# Part 4: A CI Pipeline for Automated Deployments

### **Goal: build a CI pipeline to deploy a dummy application in an automated, reliable, and repeatable manner.**

In this workshop we'll be buidling upon the last workshop to create a CI pipeline that tests, packages, publishes, and deploys a dummy application every time you commit to the application's repository. To this end, we'll be touching on some new concepts and tools:

- IAM Roles
- S3
- Cloudinit
- The Phoenix Server philosophy

I will discuss each of these when they become relevant.

#### Disclaimer
In the interest of building an end to end deployment pipeline in a single workshop, we're going to have to take some pretty serious shortcuts. What you will have built by the end of this workshop will _never_ suffice in the wild. However, it will be enough for you to grasp the essence of CI pipelining and automated deployments.

#### Tear down your infrastructure when you're done
We'll be provisioning three medium EC2 instances which cost around 9 cents an hour each. So don't forget to tear down your infrastructure when you're done.


## Set yourself up
I'll assume that you've done the previous workshops and have Ansible and the AWS cli set up on your machine.

You'll want a good overview of what you're doing throughout this workshop, so I would recommend opening the following AWS web concole services in seperate browser tabs so that you can move back and fourth easily:

- Cloudformation
- EC2
- S3
- IAM


## Build your infrastructure
We'll be going down a similar route as the last workshop. We'll use Cloudformation to create a stack of resources, and then Ansible to configure a Go server and Go agent on two seperate EC2 instances. The following commands will require some time and patience, so execute them and read on while they complete.

Let's get to it:

- go to the `part-four/infrastructure/provisioning/` directory
- provision the infrastructure:

        aws cloudformation create-stack --stack-name infrastructure --template-body "file://./infrastructure-template.json" --capabilities CAPABILITY_IAM
  
- go to your Cloudformation browser tab, you should see your infrastructure stack being created, or equivalently through the AWS cli:

        aws cloudformation describe-stacks
  
While Cloudformation creates your infrastructure, let's take a look at the stack template in `infrastructure-template.json`. The template is very similar to what we had in the previous workshop, but I've added a few resources:

|Resource|Description|
|:--|:--|
|Bucket| This is used to create an S3 bucket which we'll be using to store the packaged application|
|InstanceProfile|This resource gets added to an EC2 Instance resource and lets us associate an IAM role to an EC2 instance|
|Role|An EC2 instance assumes an IAM role, the role has policies associated to it, which determine what permissions the EC2 instance has when assuming that role|
|Policy|A description of the permissions that we wish to give to a role, we then associate that role to an EC2 instance, such that the instance has permission do certain AWS related tasks|

We'll get to S3 and buckets a little later, what's most important here is the role resource, and it's supporting resources.

#### Understanding IAM Roles
Remember when we installed the AWS cli? Remember how we had to create that AWS config file with some AWS credentials so that we could access our AWS account from the command line and do fun things like Cloudformation? Well, those credentials - obviously - are what let us do everything we wish to do with AWS. 

If you cast your mind way back, you'll recall that we've given ourselves full administration access. If you go to the IAM service tab and look at your user, you'll see that you're a part of the `Administrators` group. If you go to that group, you'll see that it has a policy called something like `AdministratorAccess-XXXXXXXXXX`. If you click `show` you'll see something like this:

```javascript
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```
What you're looking at is the policy that allows you to do whatever you want with AWS. Whenever you use the AWS cli, your credentials are used to pull up this policy, and then your desired AWS command is checked against what you can and cannot do.


Now, what if we want one of our EC2 instances to be able to do things like launch a Cloudformation stack or access S3? Without it's own credentials, it won't be able to do anything. Well, we could simply create a new user and put the right credentials on the instance, right?

Wrong.

It's really not a good idea to be throwing credentials around like candy. What we really want is to be able to give an EC2 instance a temporary set of credentials that are easy to distribute, rotate, and revoke. This is where IAM roles come in. You assign a role to an instance, and you assign policies to that role, much like the policy above, but with much stricter permissions of course. Think of it a bit like this: an IAM role is to a machine what an IAM user is to a human. See [here](http://docs.aws.amazon.com/IAM/latest/UserGuide/WorkingWithRoles.html) for a more in depth discussion on IAM roles and the problems it solves.

Now that you have a basic understanding of roles, look closely at the template, you'll see that by using the role, policy, and instanceProfile resources, we've given a bunch of permissions to our CI slave instance. We're doing this because we want our CI slave to be able to use the AWS cli to carry out tasks that we will discuss soon enough.


## Configure your CI environment
By now, your infrastructure stack should be built, like in the last workshop, we'll need to go through an irritating manual step.

- check the outputs from your stack creation:

        aws cloudformation describe-stacks
        
- if the stack is built you'll see something like this:

    ```    
    OUTPUTS	CIMasterPublicIp	XX.XX.XX.XX
    OUTPUTS	CISlavePublicIp	    XX.XX.XX.XX
    OUTPUTS	CIMasterPrivateIp	XX.XX.XX.XX
    ```
    
- grab those values and put them in the `part-four/infrastructure/configuration/inventory` file
- go to the `part-four/infrastructure/configuration/` directory
- launch Ansible to configure your CI master and CI slave instances:
    
    ```
    ansible-playbook playbook.yml -u ubuntu -i inventory --private-key="~/.ssh/main.pem"
    ```
    
This will take a little while. In the meantime, it's worth looking over `playbook.yml` to refresh your memory on what we're doing to get CI up and running. Not much has changed since the last workshop, with the exception of a few extra packages being installed on the CI slave, like Leiningen, Ruby, and the AWS cli.

When Ansible has completed, ssh to it with port forwarding such that we can access the Go Server web console:

```
ssh -L 8153:localhost:8153 ubuntu@YOUR_CI_MASTER_PUBLIC_IP -i ~/.ssh/main.pem
```

Now open `http://localhost:8153/` in your browser to access the Go server web console.


## Create your first pipeline
Now we're ready to get to the meat of this workshop. We're going to build this pipeline out incrementally. But first, let's think about the overall picture of what we want to achieve:

|Pipeline Stage|Description|
|:--|:--|
|Pull down the repository| Although not technically a stage, we'll be pulling application code down from a github repository|
|Test| Run the tests in the application code with Leiningen|
|Package| Package the application as a standalone jar with Leiningen|
|Publish| Publish the jar to S3 where we'll later fetch it to run it|
|Deploy the application| We'll be creating a new app server and deploying the application to it every time we run the pipeline|


#### Pull down the repository
There are a few steps involved in pulling the repository onto the CI slave:

- firstly, on the Go server web console, go to the `PIPELINES` tab, you will be prompted to add a pipeline
- use `dummyApplication` as the pipeline name, then select `Next`
- select `git` as the `Material Type` 
- fork this repository on github, and go to your version of it
- on the right hand pane, you should see `SSH clone URL` or `HTTPS clone URL`, copy the HTTPS URL, it should look something like this: `https://github.com/YOUR_GITHUB_NAME/devops-101.git`
- now, back on the Go server web console, put that URL into the relevant field
- check that the connection is working, and select `next`

#### Create the test stage
We're now ready to create the first stage. Fill in the fields as follows:

|Field| Value|
|:--|:--|
|Stage Name| test|
|Job Name| test|
|Task Type| more|
|Command| lein|
|Arguments| test|
|Working Directory| part-four/application|

Now press `Finish` and you'll see the beginnings of you pipeline. But we're not quite done. On the left you'll seen a pipeline structure with `test` as a sub label under `dummyApplication`, click on the `test` - this should bring up the `Stage Settings` panel. Select `Clean Working Directory` and press `Save`.

Let's explore how Go organises the structure of a pipeline.

|Component| Description|
|:--|:--|
|Pipeline| This is the top level, in our case, our pipeline is called `dummyApplication`, a pipeline can have one or more stages|
|Stages| Stages within a pipeline execute sequentially, a stage can have one or more jobs|
|Jobs| Jobs within a stage execute in *parallel*, so be careful with these, each job can have one or more tasks|
|Tasks| Tasks within a job execute sequentially, these are the bottom level guys|

Play around with Go and try to perceive this pipeline structure. when you're ready, lets run the pipeline for the first time.

#### Run the thing
Before you can run the pipeline, you'll need to make sure that the agent is enabled:

- go to the `AGENTS` tab, you should see the `ci-slave` agent
- select it and hit `enable`

Now go back to the `PIPELINES` tab and hit the pause button to unpause the pipeline. Within a few moments it should start to run:

- click the yellow (or green if it's complete) bar
- on the left hand panel you should see `test`, click on it
- now click on the `Console` tab

Within a minute or so you should see a bunch of output showing the jobs being carried out on the Go agent. Have a read through it and see if you can discern what's going on.


So what just happened? 

1. the Go server dispatched the stage to the Go agent running on the CI slave instance
2. the Go agent pulled down the repository
3. the Go agent began the `test` job
4. the job passed, therefore the stage passed, therefore the pipeline passed
5. and the world rejoiced

As a side note, the `test` job uses Leiningen, which is a project management tool for Clojure (which is what our dummy applicationis writen in). All you need to know about Leiningen is that we can use it to run our tests and build our application. You don't need to know much more, but if you like, you can learn about it [here](http://leiningen.org/).










