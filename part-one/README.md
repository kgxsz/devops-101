# Part 1: Provision an EC2 instance in AWS

###Goal: deploy a cloud server and ssh to it.

In order to achieve this goal we'll have to touch on several concepts. Don't worry if you don't completely understand some of the points we'll cover. At this stage it's enough to have a shallow understanding of these concepts, and how they contribute to us achieving our goal.

What you see below is a naive representation of what we'll be building. Notice that the three main components are the Virtual Private Cloud, the subnet, and the EC2 instance. We'll be wiring things up so as to have an EC2 instance sitting in a subnet, sitting in a VPC. We'll be routing things such that we can ssh to our EC2 instance. We'll also be touching on some security concepts.

![alt text](https://github.com/kgxsz/DevOps-101/blob/master/images/part-one-goal.png "part-one-goal")

## Get set up with AWS

In order to do any of this, you'll need an AWS account. So go ahead and register for an AWS account. I'd recommend using your full name for the account name. 

You'll be given root access credentials, sign in to AWS and have a poke around, when you're ready, move on to the next step.

#### Create an IAM group and user

The root access credentials given to you in the previous step provide unrestricted access to the account. AWS recommends that you not use these root credentials for day to day task. So we'll be using AWS' user management tool IAM to create a user for day to day tasks and put them in an administration group.

#### Create a group
- go to IAM in the services tab
- create a new group
- call it administrators
- give it administrator rights

#### Create a user
- create a user
- give it your first name (to distinguish it from your root account name)
- leave 'Generate an access key for each user' ticked
- download the access key and secret key, you'll use this later for CLI stuff
- in the user's control panel, set a password and download it
- add the user to the administrators group
- go to your IAM dashboard, you can take note of the 'IAM user sign in link'. 

Sign out and go through the link you just took note of to sign in with the IAM user name and password you just created. You should use these credentials instead of the root credentials from this point forward.
	
#### Create a key pair
Before going any further, it's worth mentioning a common point of confusion with AWS' user interface. You'll see a region name in the top right, next to the help tab. Make sure that you're in Ireland (see "Your AWS region is important" section in the main [readme](https://github.com/kgxsz/devops-101) if you would like to use another region). Whenever you create resources in a certain region, they will only be visible within that region, so make sure you create your keys in the region you intend on creating the rest of your infrastructure in.

Let's move on.

AWS provides an easy way for generating a public private key pair. When you create them, AWS holds the public key for future use and gives you the private counterpart. we'll be using these keys to ssh into our EC2 instance later.
		
- go to EC2 in the services tab
- select key pairs in the side bar
- create a key pair, call it 'main'
- your browser should have downloaded a file (or you may be prompted to do so), this is the private key.
- place your private key in the `~/.ssh` directory
- set the correct permissions on the key:

        chmod 400 ~/.ssh/main.pem
	
	
		
		
## Create a virtual private cloud
Now let's start building something. 

The first thing you need is a virtual private cloud (VPC). A VPC is a virtual network dedicated to your AWS account and isolated from all other virtual networks in the AWS cloud. The things we build from here on out will belong to, or be attached to our VPC. 

On some projects I've been on, we've used VPCs to separate resources/environments. A common setup is to use a VPC for CI resources, a VPC for Dev, another for QA, another for Production, and so on.

Once again, ensure that your AWS region is set to Ireland. Then go to VPC in the services tab, this is where you'll be managing your VPCs. You'll notice that on the left hand pane there are several pre-existing default resources.
There's a default VPC, a couple of subnets, a route table, internet gateway, and so on.

In order to work with a clean slate, and to un-clutter your understanding of what is going on, I would recommend removing the default VPC (causing all it's associated resources to also be removed). Don't panic, if you want a default VPC again later down the track, you can contact AWS support. 

Have a look and ensure that there are no longer any resources lying around (except a DHCP option set).
Now we'll be creating our VPC and associated resources:

- go to VPC in the services tab
- go to the 'your VPCs' section in the left hand pane
- create VPC
- name your VPC devops-part-one
- give it a CIDR block of `10.0.0.0/16`

Now you'll see that your new VPC was created, along with a default route table, network ACL, and security group. In the interest of learning, we won't be using those default resources, we'll be creating our own.

It's worth understanding a little about what the CIDR block is doing. The CIDR block defines a set of IP addresses for the VPC. The 16 means that the first 16 bits of the address space are fixed and the last 16 are varying. So the addresses from `10.0.0.0` to `10.0.255.255` refer to our VPC. See [this](http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
article to get a deeper understanding.

## Create a public subnet
A VPC can be divided into several subnets. You can think of subnets as as a subdivision of the VPC's IP address space. We're going to use a single subnet, and wire it up so that traffic can get to the outside world.

- go to VPC in the services tab
- go to the 'Subnets' section in the left hand pane
- create subnet
- name your subnet devops-part-one
- ensure that the VPC option points to your devops-part-one VPC 
- make the cidr block `10.0.0.0/24`

Here you'll notice that the cidr block looks similar to the VPC's cidr block, but with a trailing 24 instead of 16. This means that the first 24 bits of the address space are fixed and the last 8 are varying. So the addresses from `10.0.0.0` to `10.0.0.255` refer to this subnet in our VPC.


## Create a route table and association
Each subnet you create needs to be told how to route traffic originating from within it. We're going to create a route table and associate it to our subnet.

- go to VPC in the services tab
- go to the 'Route Tables' section in the left hand pane
- create a route table
- name it devops-part-one
- click on your newly created route table, and you'll see an information section appear below
- go to the 'Subnet Associations' tab
- edit it, and associate your devops-part-one subnet

You now have a route table associated with your subnet. If you look at the 'Routes' tab you'll see that any traffic originating in our subnet within the range `10.0.0.0/16` will be routed locally, which means that traffic targeting our VPC will be routed back into our VPC.

## Create an internet gateway
So you've got a route table routing traffic from your subnet. But it's still not getting anywhere useful. We want the subnet to be able to talk to the outside world, so let's make an internet gateway and attach it with our VPC.

- go to VPC in the services tab
- go to the 'Internet Gateway' section in the left hand pane
- create an internet gateway
- name it devops-part-one
- now attach it to your VPC

Great, you've got an internet gateway! Look at you! But it's still not doing anything, you need to route internet destined traffic from your subnet to the internet gateway:

- take note of the internet gateway id (something like `igw-xxxxxxx`)
- go to the 'Route Tables' section in the left hand pane
- select the route table you previously created
- go to routes in the tabs on the information section at the bottom of the page
- edit and add a destination of `0.0.0.0/0` with the target as the internet gateway id noted earlier

The `0.0.0.0/0` here is saying "Hey, absolutely all traffic from our subnet should be routed to our internet gateway" but there's also the `10.0.0.0/16` in there saying "Hey, this rule is a little more specific, so make sure that addresses in this range get routed to our VPC and not to the internet gateway".

## Lock down your VPC
Network Access control lists (network ACLs) are a layer of security that act as a firewall for controlling traffic in and out of a subnet. Each subnet must be associated with a Network ACLs. Let's make one.

- go to VPC in the services tab
- go to the 'Network ACL' section in the left hand pane
- create a network ACL
- name it devops-part-one
- click on your newly created ACL, and you'll see an information section below
- go to the 'Subnet Associations' tab
- edit it, and associate your devops-part-one subnet

You'll see in the details panel under inbound and outbound rules that all traffic in and out is being denied. Total lock down!

## Create security groups
Whilst Network ACLs act as the border guards for an entire subnet, you can think of security groups as the security boundary around individual EC2 instances. Let's make one and lock it down completely.

- go to VPC in the services tab
- go to the 'Security Group' section in the left hand pane
- create a security group
- make the name tag, group name, and description devops-part-one
- click on your newly created Security Group, and you'll see an information section below
- go to the 'Outbound Rules' tab
- remove the default all outbound rule

Now you've got a completely locked down security group.

A note on security: network ACLs and security groups only make up two layers of security. In the wild, you'll be configuring security for the instance itself as well. Security is a deep and complex subject. Keep in mind that just these two layers alone shouldn't make up your entire security check list! [Further reading](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Security.html) for the keen ones.

## Provision an EC2 instance
Alright, so we're now at a point where we've set up our environment and are ready to launch an EC2 instance.

You're doing so well, don't give up!

- go to EC2 in the services tab
- go to the 'Instances' section in the left hand pane
- launch an instance
- go to 'AWS Market Place' in the left hand pane
- search for 'Ubuntu Server 12.04 LTS' and select it
- select micro instance
- leave all default options
- go next and leave defaults until 'Tag Instance'
- add devops-part-one as the name tag
- select the existing security group you made earlier
- launch, and ignore the warnings
- finally, select the main key pair you made earlier

Your instance should now be launching. You'll probably have to wait a little bit. 

## Create an Elastic IP to connect to your EC2 instance
So now let's try to SSH to our instance. We have the private key so we should be able to SSH to it right? 

**Wrong!**

When you launch your EC2 instance you'll notice that it only has a private IP address. You use the private IP for communication between your instances in your VPC. You need a *public IP* to allow your instance to communicate to the outside world through your internet gateway.

- go to EC2 in the services tab
- go to the 'Elastic IPs' section in the left hand pane
- allocate new address
- associate address to your new instance

## Allow SSH connections to your EC2 instance
Now you can talk to your instance from the outside world. You could now try to ssh to your instance, but it still wouldn't work, because we've completely locked down traffic to and from the instance. A completely locked down instance isn't much use, let's open up what we need:

- go to VPC in the services tab
- go to the 'Network ACL' section in the left hand pane
- go to the 'inbound rules' tab
- add a rule to let SSH traffic into your subnet

	|rule|type|source|
	|:--:|:--:|:--:|
	|100|SSH|0.0.0.0/0|

- go to the 'outbound rules' tab
- add rule to let traffic out of your subnet to respond to the SSH traffic

	|rule|type|port range|source|
	|:--:|:--:|:--:|:--:|
	|100|custom TCP rule|1024-65535|0.0.0.0/0|

That opens up your subnet, now you need to tweak your security group for the instance

- go to the 'Security Group' section in the left hand pane
- go to the 'inbound rules' tab
- add a rule to allow ssh traffic into the instance

	|type|source|
	|:--:|:--:|:--:|
	|SSH|0.0.0.0/0|

Why didn't we change the outbound rules for security groups you ask? Well, security groups are stateful, which means that if the traffic was allowed in, the instance will be allowed to respond back out.

Now try to ssh to the instance: 

    ssh ubuntu@YOUR_ELASTIC_IP_ADDRESS -i ~/.ssh/main.pem

You're in. Take a moment to bask in the glory of what you've just achieved.

## Clean up
It's always good to clean up. Infrastructure quickly becomes messy.
Also, to prepare for part two, you need to clean up after yourself. Delete the following, in the following order:

- terminate the instance
- release the elastic IP
- delete the VPC

That's it. 
