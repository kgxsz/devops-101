## Part 4: A CI Pipeline for Automated Deployments

####**Goal: build a CI pipeline to deploy a dummy application in an automated, reliable, and repeatable manner.**

---


In this workshop we'll be buidling upon the last workshop to create a CI pipeline that tests, packages, publishes, and deploys a dummy application every time you commit to the application's repository. To this end, we'll be touching on some new concepts and tools:

- IAM Roles
- S3
- Cloudinit
- The Phoenix Server philosophy

I will discuss each of these when they become relevant.


#####Disclaimer
In the interest of building an end to end deployment pipeline in a single workshop, we're going to have to take some pretty serious shortcuts. What you will have built by the end of this workshop will _never_ suffice in the wild. However, it will be enough for you to grasp the essence of CI pipelining and automated deployments.


#####Tear down your infrastructure when you're done
We'll be provisioning three medium EC2 instances which cost around 9 cents an hour each. So don't forget to tear down your infrastructure when you're done.

---


### Set Yourself Up
I'll assume that you've done the previous workshops and have Ansible and the AWS cli set up on your machine.

You'll want a good overview of what you're doing throughout this workshop, so I would recommend opening the following AWS web concole services in seperate browser tabs so that you can move back and fourth easily:

- Cloudformation
- EC2
- S3
- IAM

---

### Get Started
We'll be going down a similar route as the last workshop. We'll use Cloudformation to create a stack of resources, and then Ansible to configure a Go server and Go agent on two seperate EC2 instances. The following commands will require some time and patience, so execute them and read on while they complete.

Let's get to it:

- go to the `part-four/infrastructure/provisioning/` directory
- provision the infrastructure:

        aws cloudformation create-stack --stack-name infrastructure --template-body "file://./infrastructure-template.json" --capabilities CAPABILITY_IAM
  
- go to your Cloudformation browser tab, you should see your infrastructure stack being created, or equivalently through the AWS cli:

        aws cloudformation describe-stacks
  
While Cloudformation creates your infrastructure, let's take a look at the stack template in `infrastructure-template.json`. The template is very similar to what we had in the previous workshop, but I've added a few resources, so let's talk about them:

|Resource|Description|
|:--|:--|
|Bucket| This is used to create an S3 bucket which we'll be using to store the packaged application|
|InstanceProfile|This resource gets added to an EC2 Instance resource and lets us associate an IAM role to an EC2 instance|
|Role|An EC2 instance assumes an IAM role, the role has policies associated to it, which determine what permissions the EC2 instance has when assuming that role|
|Policy|A description of the permissions that we wish to give to a role, we then associate that role to an EC2 instance, such that the instance has permission do certain AWS related tasks|

We'll get to S3 and buckets a little later, what's most important here is the role resource, and it's supporting resources.

##### IAM Roles
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


Now, what if we want one of our EC2 instances to be able to do things like launch a Cloudformation stack or access S3? Without it's own credentials, it won't be able to do anything. Well, we could simply create a new user and put the right credentials on the instance, right? .

Wrong.

It's really not a good idea to be throwing credentials around like candy. What we really want is to be able to give an EC2 instance a temporary set of credentials that are easy to distribute, rotate, and revoke. This is where IAM roles come in. You assign a role to an instance, and you assign policies to that role, much like the policy above, but with much stricter permissions of course. See [here](http://docs.aws.amazon.com/IAM/latest/UserGuide/WorkingWithRoles.html) for a more in depth discussion on IAM roles and the problems it solves.

---