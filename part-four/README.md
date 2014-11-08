## Part 4: A CI Pipeline for Automated Deployments
####**Goal: build a CI pipeline to deploy a dummy application in an automated, reliable, and repeatable manner.**

In this workshop we'll be buidling upon the last workshop to create a CI pipeline that tests, packages, publishes, and deploys a dummy application every time you commit to the application's repository. To this end, we'll be touching on some new concepts and tools:

- S3
- IAM Roles
- Cloudinit
- The Phoenix Server philosophy

I will discuss each of these when they become relevant.

#####Disclaimer
In the interest of building an end to end deployment pipeline in a single workshop, we're going to have to take some pretty serious shortcuts. What you will have built by the end of this workshop will _never_ suffice in the wild. However, it will be enough for you to grasp the essence of CI pipelining and automated deployments.

#####Tear down your infrastructure when you're done
We'll be provisioning three medium EC2 instances which cost around 9 cents an hour each. So don't forget to tear down your infrastructure when you're done.

### Set Yourself Up
I'll assume that you've done the previous workshops and have Ansible and the AWS cli set up on your machine.

You'll want a good overview of what you're doing throughout this workshop, so I would recommend opening the following AWS web concole services in seperate browser tabs so that you can move back and fourth easily:

- Cloudformation
- EC2
- S3
- IAM

### Get Started
We'll be going down a similar route as the last workshop. We'll use Cloudformation to create a stack of resources, and then Ansible to configure a Go server and Go agent on two seperate EC2 instances. The following commands will require some time and patience, so execute them and read on while they complete.

Let's get to it:

- go to the `part-four/infrastructure/provisioning/` directory
- provision the infrastructure:

        aws cloudformation create-stack --stack-name infrastructure --template-body "file://./infrastructure-template.json" --capabilities CAPABILITY_IAM
  
- go to your Cloudformation browser tab, you should see your infrastructure stack being created, or equivalently through the AWS cli:

        aws cloudformation describe-stacks
  
While Cloudformation creates your infrastructure, let's take a look at the stack template in `part-four/infrastructure/provisioning/infrastructure-template.json`. The template is very similar to what we had in the previous workshop, but I've added a few resources, so let's talk about them:

|Resource|Description|
|:--|:--|
|Bucket| This is used to create an S3 bucket which we'll be using to store the packaged application|
|InstanceProfile|This resource gets added to an EC2 Instance resource and lets us associate an IAM role to an EC2 instance|
|Role|An EC2 instance assumes an IAM role, the role has policies associated to it, which determine what permissions the EC2 instance has when assuming that role|
|Policy|A description of the permissions that we wish to give to a role, we then associate that role to an EC2 instance, such that the instance has permission do certain AWS related tasks|


