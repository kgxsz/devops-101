Devops 101
=================


## Part 1: Provisioning a Cloud Server

### Register for AWS

Register for an AWS account. I'd recommend using your full name for the account name.

### Create an IAM group and user

The root access keys given to you in the previous step provide unrestricted access to the account, AWS recommends creating a user and make use of those credentials instead for day to day AWS tasks

#####Create a group
- create a new group
- call it administrators
- give it administrator rights

#####Create a user
- create a user
- give it your first name (to distinguish it from your root account name)
- download the access key and secret key, you'll use this later for CLI stuff
- in the user's control panel, set a password and download it

If you now go to your IAM dashboard, you can take note of the 'IAM user sign in link'. Sign out and sign in through that link with the IAM user name and password you just created. You should use these credentials in favour of the root credentials from this point forward.
	
### Create a key pair
AWS generates key pairs for you, we'll use this to ssh into our EC2 instances later.
		
- Go to EC2 in the services tab
- Select key pairs in the side bar
- create a key pair, call it 'main'
- Your browser should have donwloaded a 'pem' file, this is the private key.
- Place your private key in the `~/.ssh` directory
- set the correct permissions on the key: `chmod 400 ~/.ssh/main.pem` 
		
		
### Create a virtual private cloud
A virtual Private Cloud is a virtual network dedicated to your AWS account, and isolated from all other virtual networks in the AWS cloud. This is your starting point.

Ensure that your AWS region is set to Ireland (in the top right corner of the web console). If you go to VPC in the services tab and have a poke around the resources on the left hand pane, you'll see that there are several pre-made default resources.
There's a default VPC, a couple of subnets, a route table, internet gateway, and so on.

In order to work with a clean slate, and to unclutter your understanding of what is going on, I would recommend removing the default VPC (causing all it's associated resources to also be removed). Don't panic, if you want a default VPC again later down the track, you can contact AWS support.

Have a look and ensure that there are no longer any resources lying around (except a DHCP option set).
Now we'll be creating our VPC and associated resources:

- go to VPC in the services tab
- go to the 'your VPCs' section in the left hand pane
- create VPC
- name your VPC devops-part-one
- give it a cidr block of 10.0.0.0/16

Now have a poke around and you'll see that your new VPC was created, along with a route table, a network ACL, and security group. In the interest of learning, we won't be using those additional resources, just the VPC.

### Create a public subnet
A VPC can be subdivided into subnets. We'll be creating a single subnet:

- go to VPC in the services tab
- go to the 'Subnets' section in the left hand pane
- create subnet
- name your subnet devops-part-one
- ensure that the VPC option points to your devops-part-one VPC 
- make the cidr block 10.0.0.0/24

### Create a route table and association
Traffic originating in subnets are insulated from the outside world and therefore need to be routed. Let's create a route table to do that:

- go to VPC in the services tab
- go to the 'Route Tables' section in the left hand pane
- create Route Table
- name it devops-part-one
- click on your newly created route table, and you'll see an information section below
- go to the 'Subnet Associations' tab
- edit it, and associate your devops-part-one subnet

You now have a route table associated with your subnet. If you look at the 'Routes' tab you'll see that any traffic originating in our subnet within the range 10.0.0.0/16 will be routed locally.

### Create an internet gateway
So you've got a route table routing trafic from your subnet. But it's still not getting anywhere useful. We want the subnet to be able to talk to the outside world, so let's make an internet gateway:

- go to VPC in the services tab
- go to the 'Internet Gateway' section in the left hand pane
- create Internet Gateway
- name it devops-part-one
- now attach it to your VPC

Great, you've got an internet gateway! But it's still not doing anything, you need to route traffic from your subnet to the internet gateway:

- take note of the internet gateway id (something like igw-xxxxxxx)
- go to the 'Route Tables' section in the left hand pane
- select the route table you previously created
- go to routes in the tabs on the information section at the bottom of the page
- edit and add a destination of 0.0.0.0/0 with the target as the internet gateway id noted earlier


### Locking down your VPC
Network ACLs are used to choose what traffic is allowed in and out of our subnet. Let's create our own network ACL and lock it down.

- go to VPC in the services tab
- go to the 'Network ACL' section in the left hand pane
- create Network ACL
- name it devops-part-one
- click on your newly created ACL, and you'll see an information section below
- go to the 'Subnet Associations' tab
- edit it, and associate your devops-part-one subnet

You'll see in the details panel under inbound and outbound rules that all traffic in and out is being denied. Total lock down!

### Security group
Whilst Network ACLs act as the border guards for an entire subnet, you can think of security groups as the security boundary around individual EC2 instances. Let's make one and lock it down completely.

- go to VPC in the services tab
- go to the 'Security Group' section in the left hand pane
- create Security Group
- make the name-tag, group-name, and description devops-part-one
- click on your newly created Security Group, and you'll see an information section below
- go to the 'Outbound Rules' tab
- remove the default all outbound rule

Now you've got a completely locked down security group.

### Provisioning an EC2 instance
You now have your own Virtual Provate Cloud, with a locked down subnet. Let's go ahead and provision an EC2 instance.

- go to EC2 in the services tab
- go to the 'Instances' section in the left hand pane
- launch instance
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

### Connecting to your EC2 instance
So now let's ssh to our instance. We have the private key so we should be able to ssh to it right? Wrong!
You need to associate a public IP to the instance so that we can hit it from the outside:

- go to EC2 in the services tab
- go to the 'Elastic IPs' section in the left hand pane
- allocate new address
- associate address to your new instance

Open a terminal and try: `ssh ubuntu@{ELASTIC_IP_ADDRESS} -i ~/.ssh/main.pem`
But nothing much happens, the connection will most likely time out. That's because we've locked the environment down.

### Allow SSH connections to your EC2 instance
A completely locked down instance isn't much use, let's open up what we need:

- go to VPC in the services tab
- go to the 'Network ACL' section in the left hand pane
- go to the 'inbound rules' tab
- add rule 100, type ssh, source 0.0.0.0/0
- go to the 'outbound rules' tab
- add rule 100, type custom TCP rule, port range 1024-65535, source 0.0.0.0/0


That's your first line of defence, now you need to tweak your security group for the instance

- go to the 'Security Group' section in the left hand pane
- go to the 'inbound rules' tab
- add type SSH and source 0.0.0.0/0

Now try this again: `ssh ubuntu@{ELASTIC_IP_ADDRESS} -i ~/.ssh/main.pem`

You're in.


### Cleaning up
To prepare for part two, you need to clean up after yourself. Delete the following, in the following order:
- terminate the instance
- release the elastic IP
- delete the VPC

That's it.


## Part 2: Infrastructure as code

### Infrastructure as code
So you've created a Virtual Provate Cloud, and you now have a running instance in there, and you're able to ssh to it.
That's great, but have you noticed how fiddly it is to do all this through the console. Imagine having tens or even hundreds of instances, hundreds of Security Groups and ACLs to manage. It wouldn't be ideal.

One of the goals of good devops is to be able to define your infrastructure as code, and have that in source control. Having the state of your infrastructure defined as code and source controlled is extremely useful for disaster recovery. It's dead easy to recreate your infrastructure from scratch (although it'd probably be a lengthy procedure).



