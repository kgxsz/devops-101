## Part 2: Infrastructure as Code

####**Goal: build a cloud environment at the press of a button.**

This workshop is going to be pretty straight forward. We're going to rebuild the environment you built in part one. But this time, we're going to avoid fiddling about with the AWS web console, and instead do it using the AWS Cloudformation tool.

Before we dive in, let's talk about what Cloudformation is, and why you would want to use such a tool.

Cast your mind back to the first workshop. We did a lot of clicking around to get our environment to the state that we wanted. Imagine having to do that all the time, or trying to recall every step needed to get to that final state. 
It's not ideal, what we really want is to be able to describe what we want as code - which is what we mean by 'infrastructure as code'. Cloudformation is an AWS tool that lets us describe our entire environment in a file and then build it for us at the press of a button. That file is known as a cloudformation stack and can be kept in source control, so that we can rebuild our infrastructure from scratch if needed.