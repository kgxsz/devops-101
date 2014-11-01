#!/usr/bin/ruby

require 'rubygems'
require 'json'

# search for old app server stacks that do not correspond to the current build
build_number = ENV['GO_PIPELINE_COUNTER']
stacks_to_be_deleted = []

filtered_stacks = JSON.parse(`aws cloudformation describe-stacks --region eu-west-1 --output json`)
stacks = filtered_stacks["Stacks"]

stacks.each do |stack|
  stack_name = stack["StackName"]
  if stack_name.match(/app-server-build-\d+$/) && !stack_name.match(/app-server-build-#{build_number}$/)
    stacks_to_be_deleted.push(stack_name)
  end
end

# delete each stack
if stacks_to_be_deleted.length == 0
  puts "No stacks to delete"
  exit
end

stacks_to_be_deleted.each do |stack_name|
  puts "Deleting stack: #{stack_name}"
  `aws cloudformation delete-stack --stack-name #{stack_name} --region eu-west-1`
end

# ensure that all stacks awaiting deletion are gone
sleep(30)
loop do
  stacks_awaiting_deletion = []
  filtered_stacks = JSON.parse(`aws cloudformation describe-stacks --region eu-west-1 --output json`)
  stacks = filtered_stacks["Stacks"]

  stacks.each do |stack|
    stack_name = stack["StackName"]
    if stack_name.match(/app-server-build-\d+$/) && !stack_name.match(/app-server-build-#{build_number}$/)
      stacks_awaiting_deletion.push(stack)
    end
  end

  if stacks_awaiting_deletion.length != 0
    stacks_awaiting_deletion.each do |stack|
      stack_name = stack["StackName"]
      stack_status = stack["StackStatus"]
      puts "Awaiting deletion of #{stack_name} with status of #{stack_status}"
      if stack_status != "DELETE_IN_PROGRESS"
        exit 1
      end
    end
  else
    puts "Stack deletion complete"
    break
  end
  sleep(15)
end
