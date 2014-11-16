# Part 3: Provision and Configure a CI Environment
###**Goal: create your CI environment in the cloud using Ansible.**

So far, you've learnt how to provision a cloud environment with Cloudformation, but it's all for naught if you don't configure your EC2 instances to do as you wish. So in this workshop we're going to use Ansible to configure a CI environment. Specifically, we're going to configure two EC2 instances:

- A CI master running the Go server
- A CI slave running a Go agent

![alt text](https://github.com/kgxsz/DevOps-101/blob/master/images/part-three-goal.png "part-three-goal")


#### A bit about Ansible
If you were really keen, you could use Cloudformation to provision a couple of EC2 instances, connect to each one and painstakingly configure the instance by hand. But that's not ideal, what we need is a tool that configures our instances for us in a repeatable way, at the press of a button. 

Enter Ansible. Ansible is a configuration tool that you run locally, you tell it which remote host to configure, and Ansible will ssh to it and get the job done.

#### Disclaimer
What we're about to build is *very* simple, with the intention being that this is a starting point for gaining a deeper understanding of these concepts and tools. Only use a set up like this for a toy project. There are many more considerations and improvements you would need to make in the wild.

#### Tear down your infrastructure when you're done
We'll be provisioning two medium EC2 instances which cost around 9 cents an hour each. So don't forget to tear down your infrastructure when you're done.

## Get set up with Ansible
To get going, you'll need Ansible.

- get it with homebrew (`brew install ansible`)
- or get it [here](http://docs.ansible.com/intro_installation.html)

I'll assume that you've done part one and two so you already have an AWS account and the CLI ready to go.
 
## Provision the Infrastructure
We'll be provisioning the infrastructure with AWS Cloudformation like we did in part two. You will find a template describing our entire infrastructure in `part-three/infrastructure/provisioning/`.

Have a look at the template, notice that it's not much different from the template in part two, but we've added an extra EC2 instance and EIP, some additions to the security group and some network ACL entries. The two EC2 instances are:

1. CI master: where we'll be running the Go server
2. CI slave: where we'll be running the Go agent


We've also added a new section called outputs. We're using outputs to obtain information that only exists *after* our infrastructure stack has ben created. In particular, we're interested in the public and private IPs of the CI master and slave, but these values are assigned dynamically by AWS and not known upfront. Outputs let's us get at that information easily.

Let's get to it.

- go to the `part-three/infrastructure/provisioning/` directory
- provision the infrastructure:

        aws cloudformation create-stack --stack-name infrastructure --template-body "file://./infrastructure-template.json"
        
- take a look at the AWS web console, after a little while you should see two EC2 instances being created
- check the status on the Cloudformation task with:

        aws cloudformation describe-stacks
        
    When Cloudformation has created the infrastructure stack, we can view the outputs with the above command. You should see something like this:

    ```    
    OUTPUTS	CIMasterPublicIp	XX.XX.XX.XX
    OUTPUTS	CISlavePublicIp	    XX.XX.XX.XX
    OUTPUTS	CIMasterPrivateIp	XX.XX.XX.XX

    ```
    We'll use these outputs in just a second.
    
## Configure the EC2 Instances  
You've provisioned your infrastructure. Now it's time to configure the EC2 instances. By configure, what I really mean is the collection of tasks you need to carry out on your EC2 instances to have the Go Server and agent up and running. We're going to use Ansible to carry out those tasks.

#### The inventory file

Given that Ansible runs from your local machine and configures target instances remotely, we need to tell it where those target instances are. To this end, we use an `inventory` file to list our remote instances that we intend to configure. We won't be setting up DNS in this workshop, so we're going to need an ugly manual step to take the IP addresses we obtained from the Cloudformation outputs, and put them into the `inventory` file.

- open `part-three/infrastructure/configuration/inventory` in your favourite editor
- copy the IP addresses you got from the Cloudformation outputs like so:

    ```
    [ci-master]
    YOUR_CI_MASTER_PUBLIC_IP

    [ci-slave]
    YOUR_CI_SLAVE_PUBLIC_IP

    [ci-slave:vars]
    ci_master_private_ip=YOUR_CI_MASTER_PRIVATE_IP
    ````
            
    The first four lines associate a name to an IP address.
    The last two lines are a little different, they are setting up a variable that will be used by one of our Ansible tasks.
    Please take care to ensure that this is correct.
    
#### The playbook

So now we have an inventory file to tell Ansible where to go, so all that's left is a file to tell Ansible what tasks to carry out on our instances.

- go to the `part-three/infrastructure/configuration/` directory
- open `playbook.yml` in your favourite editor and have a look around

The playbook is simply a list of tasks, and which hosts to apply those tasks to. It should be fairly clear that the tasks under `hosts: all` get applies to both the `ci-master` and `ci-slave`, whereas tasks under `hosts: ci-master` only apply to `ci-master` and so on. You'll also notice that the name of the hosts (`ci-master` and `ci-slave`) correspond to those in the inventory file.

The tasks are pretty self explanatory, the name of the task tell us what we're doing in a human readable way, the next line defines the Ansible module we're using to carry out the task (see [here](http://docs.ansible.com/modules_by_category.html) to view all modules) and then you have additional options like "sudo".

Also worth mentioning is the `handlers` section. Handlers are like tasks but are only carried out at the end of a playbook *if they have been notified by a regular task*. Take a look at the second last task, theres a `notify` option, which says "if I just updated the `/etc/default/go-agent` file, then notify that handler to restart the go agent". It may seem odd to you that we might notify the handler on some occasions, and not on others. To understand this, we need to understand Ansible's idempotent nature.

Idempotency in Ansible simply means that you can run a playbook over and over again, and Ansible will only make the changes it needs to make in order to achieve the end state. Ansible reports a task as `changed` if configuration had to be done to achieve the end state, otherwise it reports the task as `ok` or `skipping` if the end state has already been achieved.

So in this particular example, we have a task that adds a line to a go agent configuration file on the CI slave instance. If the line doesn't exist, Ansible adds it, and then notifies the handler to restart the go agent at the end of the playbook. If the line exists, Ansible doesn't do anything and the handler is not notified. All this will make more sense as you start to use Ansible.

Finally, recall the `ci_master_private_ip` variable we defined in the inventory file, you'll notice that we've used that variable in the second last task. We reference the variable as `{{ ci_master_private_ip }}`.


#### Run Ansible
Now that we have a basic understanding of the inventory and playbook, let's use them:

- in the `part-three/infrastructure/configuration/` directory:

        ansible-playbook playbook.yml -u ubuntu -i inventory --private-key="~/.ssh/main.pem"
  Here, we're telling ansible which playbook and inventory file to use, as well as what user and private key to use for ssh. You will be prompted, say yes to both, and then watch as Ansible configures your instances
  
That's it. Once Ansible has finished, try running it again, you'll notice that it's a lot faster and the tasks are reporting as `ok` or `skipping`, that's idempotency in action.

#### Organising Ansible
For this workshop it's sufficient to have a single playbook and an inventory file with a variable defined within it. For real world projects, however, you will need to separate tasks out into 'roles', and variables should live in their own files, not in the inventory file.
  
## Connect to the Go Server   
Your Go server and agent should now be up and running. The Go server is listening on port 8153 of the CI master instance, but you won't be able to access it since we've blocked all incoming traffic from the outside world other than ssh. So we're going to use ssh port forwarding, which simply forwards a given address and port to us when we have an ssh connection open.

- connect to the CI master and set up port forwarding with: 
        
        ssh -L 8153:localhost:8153 ubuntu@YOUR_CI_MASTER_PUBLIC_IP -i ~/.ssh/main.pem
        
    Here, we've forwarded `localhost:8153`, which is the host and port of the Go server as seen from the CI master instance's perspective, to our local port 8153.
    
- open `http://localhost:8153/` in your browser to access the Go server web console
- go to the agents tab and you should be able to see that the go agent has connected, if it hasn't, you may need to ssh to the CI slave instance and restart the go-server manually: 

        ssh ubuntu@YOUR_CI_SLAVE_PUBLIC_IP -i ~/.ssh/main.pem
        sudo service go-agent start

You now have a Go server running with an agent attached ready to configure a pipeline to do your bidding.

## Clean Up
That's it! You've created your CI environment. You're in a good place now, you can tear down and rebuild this CI environment at the press of a button. The next step is to configure a CI pipeline and deploy a dummy application, but we're not going to do that in this workshop. So, we'll be ending it here. But before you go, do not forget to tear down the infrastructure:

        aws cloudformation delete-stack --stack-name infrastructure

