## Part 2: Your Infrastructure as Code

####**Goal: build your cloud infrastructure at the press of a button.**

This workshop is going to be pretty straight forward. We're going to rebuild the environment you built in part one. But this time, we're going to avoid fiddling about with the AWS web console, and instead, do it using the AWS Cloudformation tool.

Before we dive in, let's talk about what Cloudformation is, and why you would want to use such a tool.

##### Cloudfromation and infrastructure as code

Cast your mind back to the first workshop. We did a lot of clicking around to get our environment to the state that we wanted. Imagine having to do that all the time, or trying to recall every step needed to get to that final state. 
It's not ideal, what we really want is to be able to describe the infrastructure we want as code - which is what we mean by 'infrastructure as code'. 

Cloudformation is an AWS tool that lets us describe a set of resources in a file called a template. Those resources make up our infrastructure. When we feed a template file to Cloudformation, it goes away and builds out the "stack" of resources that you described in that template. That template is simply a file, so it can be kept in source control, so that we can rebuild our infrastructure from scratch if needed.

![alt text](https://github.com/kgxsz/DevOps-101/blob/master/images/part-two-goal.png "part-two-goal")

### Getting set up with the AWS command line interface

We're going to be doing this workshop through the command line rather than through the AWS web console. So you're going to need the AWS cli.

- get it with homebrew: `brew install awscli`
- or get it [here](https://aws.amazon.com/cli/)

If you're doing this workshop right after the last one, you may have noticed that a file was downloaded by your browser when you created an IAM user. The file is called something like `credentials.csv`. It might still be in your downloads directory. If it is, great! You can skip to the 'configure your AWS cli' section. If not, no biggie - we'll create it now.

#####Create access keys
- go to your AWS console using the IAM username and password you created in the previous workshop. Recall that your sign-in page url is of the form `https://YOUR_ACCOUNT_NAME.signin.aws.amazon.com/console/`
- if you can't remember the sign-in page url, or it's not working:
	- you can access your AWS account with your root credentials
	- once in, go to IAM in the services tab
	- go to dashboard, and take note of the IAM users sign-in link
	- sign out and then back in using the link and your IAM username and password
	- if you're still stuck, go back to the first workshop and follow the instructions
- once you're in, go to IAM in the services tab
- then go to users, and click on yourself
- down the bottom you should see the "access credentials" section
- manage access keys
- create an access key (and delete the old one since you've probably lost it)
- download credentials
- you should now have a file called `credentials.csv` in your downloads directory

#####Configure your AWS cli
In order to use the AWS cli with your account, it needs to know your AWS account credentials.

- open `credentials.csv` and take note of the `access key id` and the `secret access key`
- create an aws directory and create a config file in there: 

        mkdir ~/.aws
        touch ~/.aws/config
     
- open the file in your favourite editor and put the following in:

	```
	[default]
	output = text
	region = eu-west-1
	aws_access_key_id = YOUR_ACCESS_KEY_ID
	aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
	```
	Note that the region here may not be suitable for you, here we're using Ireland, but you can change it to whatever you want.


Now, from your command line, try `aws help`, you should see a manual for using the aws cli.


You're ready to create your first stack!

### Create your first stack
We're going to be using the cloudformation module within the AWS cli to create a stack. Try `aws cloudformation help` at any point if you want to know more about how to use cloudformation.

In order to create a stack, we'll need to create a **template** to describe a set of resources, or a *stack* of resources. We'll feed that template file to the cloudformation module and it will go and create that stack of resources remotely in your AWS account. Let's start with something simple.

Now, if you haven't already done so, pull down this repository and open `part-two/templates/template-one.json`. You should see the following:

```javascript
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description" : "devops-part-two, template one",
  "Resources" : {
    "VPC" : {
      "Type" : "AWS::EC2::VPC",
      "Properties" : {
        "CidrBlock" : "10.0.0.0/16",
        "Tags" : [ {"Key" : "Name", "Value" : "devops-part-two"} ]
      }
    }
  }
}
```

This is pretty straight forward:

- the first line defines the format of the file, don't change that date
- the second line let's us describe what the stack is all about
- the third line is the meat, it opens up the resources section where we desribe our *stack* of resources
- here, we only have one resource, it's a VPC, and we've named it "devops-part-two" in the tags

There is really thorough [documentation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) and examples available to help you describe the resources you need in a template file.

Let's create this stack!

- go to the templates directory (`part-two/templates`)
- create the stack: 

        aws cloudformation create-stack --stack-name stack-one --template-body "file://./template-one.json"
- check out the stack's status with: 

        aws cloudformation describe-stacks 
  you should see something like `CREATE_IN_PROGRESS` or `CREATE_COMPLETE`
- go to the AWS web console and look at cloudformation in the services tab, you should see the template-one stack
- wait for the stack to complete (refresh the page to update it's status)
- go to VPC in the services tab
- you should now see the 'devops-part-two' VPC

Congratulations! You've just created your first stack with cloudformation!

Now let's tear that stack down: 
        
    `aws cloudformation delete-stack --stack-name stack-one`
Again, you can check the stack status to see how the delete is going, or you can check on the web console.

Once it's deleted, that VPC should no longer exist, the cloudformation section on the web console should be empty, and the describe stacks command should yield absolutely nothing.


How easy was that?


### Create a bigger stack

##### Understand the template

Do you remember all the resources you created in part one? Here's a list to remind you:


|Resource|Description|
|:--|:--|
|VPC|our virtual network, home to our resources|
|Subnet|a subdivion of our VPC, home to our EC2 instance|
|Route table|a list of rules on how to route traffic to/from a subnet|
|Internet gateway|the thing you route traffic to so that you can talk to the internet|
|Network ACL|security at the subnet level, filters traffic in and out of a subnet|
|Security group|security at the EC2 instance level, filters traffic in and out of an EC2 instance|
|Elastic IP|the IP you associate with your EC2 instance so that you can talk to it from the outside world|
|EC2 instance|your instance in the cloud|

What we want now is to describe a stack of these resources in a single template file (in the wild you probably won't want to put it all in a single file, but for now this is fine).

- go to the templates directory (`part-two/templates`)
- open `template-two`
- have a look around and try to identify each of the above resources in the template file, you'll notice that the resources are defined exactly as we did in the first workshop

Once again, check out the [documentation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) for each resource if you want to know more about the resource properties, or if you are having trouble understanding the syntax.

We've kept the template as simple as possible here, there's a lot more you can do with templates, such as parameters, mappings, and conditions - see the template [documentation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html) for more information.

You may have noticed that there are some resources declared in the template that you haven't seen before. Let's go over these briefly:

|Resource|Description|
|:--|:--|
|SubnetRouteTableAssociation| This is used to associate the subnet resource to the route table resource|
|VPCGatewayAttachment|This is used to attach the internet gateway resource to the VPC resource|
|Route|When we declare the route table resource we don't actually describe any routes, this resource describes the routes for that route table|
|NetworkACLEntry|We describe a netwrok ACL resource, and this resource allocates entries to it|
|SubnetNetworkAclAssociation|This resource lets you associate the network ACL resource with the subnet resource|

Note that if you are **not** using Ireland as your location, you will need to edit the file to change the `availibilityZone` and `ImageId` values to your specific region.

##### Build the infrastructure

Now let's feed this template to cloudformation and watch it build our infrastructure!

From the `part-two/templates` directory:

    aws cloudformation create-stack --stack-name template-two --template-body "file://./template-two.json"

check out the stack's status with: 

    aws cloudformation describe-stacks 
    

This should take a little while to complete, but when it is, you can have a look through your resources on the AWS web console and you'll see that all is in place.

Now, ssh to your newly created instance once it's finished initializing:
   
    ssh ubuntu@YOUR_ELASTIC_IP_ADDRESS -i ~/.ssh/main.pem


##### Tear down the infrastructure

So you want clean down your infrastracture when you're done:

    aws cloudformation delete-stack --stack-name template-two
    
### Wrapping up

Let's take a moment to think about what you just did. You were able to build and tear down your infrastructure at the press of a button. You have a file describing your entire infrastructure that you can keep in source control. You're in a good place because you can always rebuild your infrastructure from nothing. Doesn't it feel nice?










