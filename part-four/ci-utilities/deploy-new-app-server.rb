#!/usr/bin/ruby

require 'rubygems'
require 'json'

def extract_subnet_id
  describe_subnets_command = "aws ec2 describe-subnets \
                              --filters Name=tag:aws:cloudformation:logical-id,Values=Subnet \
                              --region eu-west-1 \
                              --output json"
  subnets = JSON.parse(`#{describe_subnets_command}`)["Subnets"]
  subnet_id = subnets.first["SubnetId"]
  puts "Extracted subnet id: #{subnet_id}"
  return subnet_id
end

def extract_security_group_id
  describe_security_groups_command = "aws ec2 describe-security-groups \
                                      --filters Name=tag:aws:cloudformation:logical-id,Values=SecurityGroup \
                                      --region eu-west-1 \
                                      --output json"
  security_groups = JSON.parse(`#{describe_security_groups_command}`)["SecurityGroups"]
  security_group_id = security_groups.first["GroupId"]
  puts "Extracted security group id: #{security_group_id}"
  return security_group_id
end

def commence_creation_of_stack(build_number, subnet_id, security_group_id)
  puts "Commencing creation of stack: app-server-build-#{build_number}"
  `aws cloudformation create-stack \
  --stack-name app-server-build-#{build_number} \
  --template-body "file://../infrastructure/provisioning/app-server-template.json" \
  --region eu-west-1 \
  --output text \
  --parameters \
  ParameterKey=SubnetId,ParameterValue=#{subnet_id} \
  ParameterKey=SecurityGroupId,ParameterValue=#{security_group_id} \
  ParameterKey=BuildNumber,ParameterValue=#{build_number} \
  --capabilities CAPABILITY_IAM`
end

def check_that_the_stack_has_been_created(build_number)
  describe_stacks_command = "aws cloudformation describe-stacks \
                             --stack-name app-server-build-#{build_number} \
                             --region eu-west-1 \
                             --output json"
  stacks = JSON.parse(`#{describe_stacks_command}`)["Stacks"]
  stack_status = stacks.first["StackStatus"]

  puts "Awaiting creation of app-server-build-#{build_number} with status of #{stack_status}"

  if stack_status == "CREATE_COMPLETE"
    puts "Stack creation complete"
    exit 0
  elsif stack_status != "CREATE_IN_PROGRESS"
    puts "Stack creation failed"
    exit 1
  end
end

def main
  build_number = ENV['GO_PIPELINE_COUNTER']
  subnet_id = extract_subnet_id
  security_group_id = extract_security_group_id
  commence_creation_of_stack(build_number, subnet_id, security_group_id)
  loop do
    check_that_the_stack_has_been_created(build_number)
    sleep(15)
  end
end

main
