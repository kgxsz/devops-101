## Part 3: Provision and Configure a CI Environment
####**Goal: build out your CI environment in the cloud using Ansible.**

So far, you've learnt how to provision a cloud environment with cloudformation, but it's all for naught if you don't configure your EC2 instances to do as you wish. So in this workshop we're going to use Ansible to configure a CI environment. Specifically, we're going to configure two EC2 instances:

- A CI master running the Go server
- A CI slave running a Go agent

#####A bit about Ansible
If you were really keen, you could use cloudformation to provision a couple of EC2 instances, connect to each one and painstakingly install the things you need by hand. But that's not ideal, what we need is a tool that configures our instances for us in a repeatable way, at the press of a button. 

Enter Ansible. Ansible is a configuration tool that you run locally, you tell it which remote host to configure, and Ansible will ssh to it and ge thte job done.

#####Be careful
What we're about to build is *very* simple, with the intention being that this is a starting point for gaining a deeper understanding of these concepts and tools. Only use a set up like this for a toy project. There are many considerations and improvements you would need to make to build real world infrastructure.

#####Tear down your infrastructure when you're done
Don't forget to tear this down when you're done otherwise it will cost you 18 cents an hour.


Anyway, let's get started.

### Create the Infrastructure

You will find a template describing our entire infratructure in `templates/infratructure.json`


**WORK IN PROGRESS:**

- In templates: 

        aws cloudformation create-stack --stack-name infrastructure --template-body "file://./infrastructure-template.json"`

- Check `aws cloudformation describe-stacks` until the infrastructure is complete
- Again, check the outputs from `aws cloudformation describe-stacks`, pull out the values and put them in `configuration/inventory`

```
[ci-master]
YOUR_CI_MASTER_PUBLIC_IP

[ci-slave]
YOUR_CI_SLAVE_PUBLIC_IP

[ci-slave:vars]
ci_master_private_ip=YOUR_CI_MASTER_PRIVATE_IP
```

- in `configuration/`, do `ansible-playbook playbook.yml -u ubuntu -i inventory --private-key="~/.ssh/main.pem"`
- connect with `ssh -L 8153:localhost:8153 ubuntu@YOUR_CI_MASTER_PUBLIC_IP -i ~/.ssh/main.pem`
- open `http://localhost:8153/`

- Tear it down `aws cloudformation delete-stack --stack-name infrastructure`

