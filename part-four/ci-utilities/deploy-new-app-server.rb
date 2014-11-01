#!/usr/bin/ruby

require 'rubygems'
require 'json'

# extract subnet and security group ids
subnet_logical_id = "Subnet"
security_group_logical_id = "SecurityGroup"

filtered_subnets = JSON.parse(`aws ec2 describe-subnets --filters Name=tag:aws:cloudformation:logical-id,Values=#{subnet_logical_id} --region eu-west-1 --output json`)
filtered_security_groups = JSON.parse(`aws ec2 describe-security-groups --filters Name=tag:aws:cloudformation:logical-id,Values=#{security_group_logical_id} --region eu-west-1 --output json`)

subnet_id = filtered_subnets["Subnets"].first["SubnetId"]
security_group_id = filtered_security_groups["SecurityGroups"].first["GroupId"]

puts "Extracted subnet id: #{subnet_id}"
puts "Extracted security group id: #{security_group_id}"

# launch the app server stack
build_number = ENV['GO_PIPELINE_COUNTER']

puts "Launching the app server stack for build #{build_number}"

`aws cloudformation create-stack \
--stack-name app-server-build-#{build_number} \
--template-body "file://../infrastructure/provisioning/app-server-template.json" \
--region eu-west-1 \
--output text \
--parameters \
ParameterKey=SubnetId,ParameterValue=#{subnet_id} \
ParameterKey=SecurityGroupId,ParameterValue=#{security_group_id} \
ParameterKey=BuildNumber,ParameterValue=#{build_number}`

# wait for the stack to be created
sleep(30)
loop do
  filtered_stacks = JSON.parse(`aws cloudformation describe-stacks --stack-name app-server-build-#{build_number} --output json --region eu-west-1 --output json`)
  stack_status = filtered_stacks["Stacks"].first["StackStatus"]
  puts "Stack creation status: #{stack_status}"

  if stack_status == "CREATE_COMPLETE"
    exit 0
  elsif stack_status != "CREATE_IN_PROGRESS"
    exit 1
  end

  sleep(15)
end
