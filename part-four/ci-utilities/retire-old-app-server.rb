#!/usr/bin/ruby

require 'rubygems'
require 'json'

def find_old_stacks
  old_stacks = []
  build_number = ENV['GO_PIPELINE_COUNTER']
  describe_stacks_command = "aws cloudformation describe-stacks \
                             --region eu-west-1 \
                             --output json"
  stacks = JSON.parse(`#{describe_stacks_command}`)["Stacks"]
  stacks.each do |stack|
    stack_name = stack["StackName"]
    if stack_name.match(/app-server-build-\d+$/) && !stack_name.match(/app-server-build-#{build_number}$/)
      old_stacks.push(stack)
    end
  end
  return old_stacks
end

def commence_deletion_of_stacks(stacks_to_be_deleted)
  if stacks_to_be_deleted.length == 0
    puts "No stacks to delete"
    exit 0
  end
  stacks_to_be_deleted.each do |stack|
    stack_name = stack["StackName"]
    puts "Commencing deletion of stack: #{stack_name}"
    `aws cloudformation delete-stack \
     --stack-name #{stack_name} \
     --region eu-west-1`
  end
end

def check_that_stacks_have_been_deleted
  stacks_awaiting_deletion = find_old_stacks
  if stacks_awaiting_deletion.length == 0
    puts "Stack deletion complete"
    exit 0
  end
  stacks_awaiting_deletion.each do |stack|
    stack_name = stack["StackName"]
    stack_status = stack["StackStatus"]
    puts "Awaiting deletion of #{stack_name} with status of #{stack_status}"
    if stack_status != "DELETE_IN_PROGRESS"
      puts "Stack deletion failed"
      exit 1
    end
  end
end

def main
  stacks_to_be_deleted = find_old_stacks
  commence_deletion_of_stacks(stacks_to_be_deleted)
  loop do
    check_that_stacks_have_been_deleted
    sleep(15)
  end
end

main
