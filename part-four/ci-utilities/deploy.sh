#!/bin/sh

echo "deploying for build number $GO_PIPELINE_COUNTER"

# extract the subnet and security group ids
RELEVANT_OUTPUTS=`aws cloudformation describe-stacks --region eu-west-1 --output text | egrep "SubnetId|SecurityGroupId"`
SUBNET_ID=`echo $RELEVANT_OUTPUTS | awk '{print $3}'`
SECURITY_GROUP_ID=`echo $RELEVANT_OUTPUTS | awk '{ print $6 }'`

# deploy the app server
`aws cloudformation create-stack \
--stack-name app-server-build-$GO_PIPELINE_COUNTER \
--template-body "file://../infrastructure/provisioning/app-server-template.json" \
--region eu-west-1 \
--output text \
--parameters \
ParameterKey=SubnetId,ParameterValue=$SUBNET_ID \
ParameterKey=SecurityGroupId,ParameterValue=$SECURITY_GROUP_ID
ParameterKey=BuildNumber,ParameterValue=$GO_PIPELINE_COUNTER`
