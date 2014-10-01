## Part 2: Your Infrastructure as Code

####**Goal: build a cloud environment at the press of a button.**

This workshop is going to be pretty straight forward. We're going to rebuild the environment you built in part one. But this time, we're going to avoid fiddling about with the AWS web console, and instead do it using the AWS Cloudformation tool.

Before we dive in, let's talk about what Cloudformation is, and why you would want to use such a tool.

##### Cloudfromation and infrastructure as code

Cast your mind back to the first workshop. We did a lot of clicking around to get our environment to the state that we wanted. Imagine having to do that all the time, or trying to recall every step needed to get to that final state. 
It's not ideal, what we really want is to be able to describe the infrastructure we want as code - which is what we mean by 'infrastructure as code'. 

Cloudformation is an AWS tool that lets us describe a set of resources in a file called a template. Those resources make up our infrastructure. When we feed a template file to Cloudformation, it goes away and builds out the "stack" of resources that you described in that template. That template is simply a file, so it can be kept in source control, so that we can rebuild our infrastructure from scratch if needed.

![alt text](https://github.com/kgxsz/DevOps-101/blob/master/part-two/img/goal.png "part-two-goal")

### Getting set up with the AWS command line interface

We're going to be doing this workshop through the command line rather than through the AWS web console. So you're going to need the AWS cli.

- get it with homebrew: `brew install awscli`
- or get it [here](https://aws.amazon.com/cli/)

If you're doing this workshop right after the last one, you may have noticed that a file was downloaded by your browser when you created an IAM user. The file is called something like `credentials.csv`. It might still be in your downloads directory. If it is, great! You can skip to the 'configure your AWS cli section'. If not, no biggie - we'll create it now.

#####Create access keys
- go to your AWS console using the IAM username and password you created in the previous workshop. Recall that your sign-in page url is of the form `https://YOUR_ACCOUNT_NAME.signin.aws.amazon.com/console/`
- if you can't remember the sign-in page url, or it's not working:
	- you can access your AWS account with your root credentials
	- once in, go to IAM in the services tab
	- go to dashboard, and take note of the IAM users sign-in link
	- sign out and then back in using the link and your IAM username and password
	- if you're still stuck, go back to the first workshop and follow the instructions
- once you're in, go to IAM in the service
- then go to users, and click on yourself
- down the bottom you should see the "access credentials" section
- manage access keys
- create an access key (and delete the old one since you've probably lost it)
- download credentials
- you should now have a file called `credentials.csv` in your downloads directory

#####Configure your AWS cli
In order to use the AWS cli with your account, it needs to know your AWS account credentials.

- open `credentials.csv` and take note of the `access key id` and the `secret access key`
- create an aws directory `mkdir ~/.aws` and create a config file in there `touch ~/.aws/config`
- open the file in your favourite editor and put the following in:

	```
	[default]
	output = text
	region = eu-west-1
	aws_access_key_id = YOUR_ACCESS_KEY_ID
	aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
	```
	Note that the region here may not be suitable for you, here we're using Ireland.


Now, from your command line, try `aws help`, you should see a manual for using the aws cli.
You're ready to describe your first stack!

### Create your first stack
We're going to be using the cloudformation module within the AWS cli to create a stack. Try `aws cloudformation help` at any point if you want to know more about how to use cloudformation.

In order to create a stack, we'll need to create a **template** to describe a set of resources, or a *stack* of resources. We'll feed that template file to the cloudformation module and it will go and create that stack of resources in your AWS account. Let's start simple though.



