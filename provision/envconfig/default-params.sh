#!/bin/bash

get_sns_topic_arn(){
    aws cloudformation describe-stack-resources \
        --stack-name ${1} \
        2>/dev/null \
        | jq -r '.StackResources | .[] | select(.ResourceType == "AWS::SNS::Topic") | select(.LogicalResourceId | contains("'${2}'")) | .PhysicalResourceId' \
        | tr '\n' ',' \
        | sed -e 's/,$//g'
}

get_vpc_id(){
    aws cloudformation describe-stack-resources \
        --stack-name ${1} \
        --logical-resource-id "VPC" \
        2>/dev/null \
        | jq -r '.StackResources | .[] | .PhysicalResourceId'
}

get_resource(){
    aws cloudformation describe-stack-resources \
        --stack-name ${1} \
        --logical-resource-id ${2} \
        2>/dev/null \
        | jq -r '.StackResources | .[] | .PhysicalResourceId'
}

get_output(){
    aws cloudformation describe-stacks \
        --stack-name ${1} \
        2>/dev/null \
        | jq -r '.Stacks | .[] | .Outputs | .[] | select(.OutputKey == "'${2}'") | .OutputValue'
}

get_vpc_subnets(){
    aws cloudformation describe-stack-resources \
        --stack-name ${1} \
        2>/dev/null \
        | jq -r '.StackResources | .[] | select(.ResourceType == "AWS::EC2::Subnet") | select(.LogicalResourceId | contains("'${2}'")) | .PhysicalResourceId' \
        | tr '\n' ',' \
        | sed -e 's/,$//g'
}

get_sns_topics(){
    aws cloudformation describe-stack-resources \
        --stack-name ${1} \
        2>/dev/null \
        | jq -r '.StackResources | .[] | select(.ResourceType == "AWS::SNS::Topic") | .PhysicalResourceId' \
        | sed -e 's/^/"/g;s/$/"/g' \
        | tr '\n' ',' \
        | sed -e 's/,$//g'
}

#These are the devops keys used by aws cloudformation for create-stack and update-stack
#export AWS_ACCESS_KEY_ID=""
#export AWS_SECRET_ACCESS_KEY=""
if [ -z $AWS_ACCESS_KEY_ID$AWS_SECRET_ACCESS_KEY ]; then echo "Enviroment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY must be defined"; exit; fi

AWS_KEYNAME=${AWS_KEYNAME:-"${RADAR_ENVIRONMENT}"}; export AWS_KEYNAME
AWS_KEYFILE=${AWS_KEYFILE:-"~/.ssh/${RADAR_ENVIRONMENT}.pem"}; export AWS_KEYFILE

AWS_REGION=${AWS_REGION:-"us-east-1"}; export AWS_REGION
AWS_REGION_NORM=${AWS_REGION_NORM:-`echo $AWS_REGION | sed -e 's/-//g'`}; export AWS_REGION_NORM

#SNS template settings
##template inputs
RADAR_SNS_TEMPLATE=${RADAR_SNS_TEMPLATE:-"radar-sns-v1.json"}; export RADAR_SNS_TEMPLATE
RADAR_SNS_VPC_STACKNAME=${RADAR_SNS_VPC_STACKNAME:-"${AWS_REGION_NORM}-sns-vpc-${RADAR_ENVIRONMENT}"}; export RADAR_SNS_VPC_STACKNAME

#VPC template settings
##template inputs
RADAR_VPC_TEMPLATE=${RADAR_VPC_TEMPLATE:-"radar-vpc-v1.json"}; export RADAR_VPC_TEMPLATE
RADAR_VPC_STACKNAME=${RADAR_VPC_STACKNAME:-"${AWS_REGION_NORM}-vpc-${RADAR_ENVIRONMENT}"}; export RADAR_VPC_STACKNAME
RADAR_VPC_ZONE1=${RADAR_VPC_ZONE1:-"${AWS_REGION}a"}; export RADAR_VPC_ZONE1
RADAR_VPC_ZONE2=${RADAR_VPC_ZONE2:-"${AWS_REGION}d"}; export RADAR_VPC_ZONE2
RADAR_VPC_SSHLOCATION=${RADAR_VPC_SSHLOCATION:-"0.0.0.0/0"}; export RADAR_VPC_SSHLOCATION
##template outputs
RADAR_VPC_ID=${RADAR_VPC_ID:-`get_vpc_id ${RADAR_VPC_STACKNAME}`}; export RADAR_VPC_ID
RADAR_VPC_PUBLICSUBNETS=${RADAR_VPC_PUBLICSUBNETS:-`get_vpc_subnets ${RADAR_VPC_STACKNAME} "Public"`}; export RADAR_VPC_PUBLICSUBNETS
RADAR_VPC_PUBLICSUBNET_ZONE1=${RADAR_VPC_PUBLICSUBNET_ZONE1:-`get_resource ${RADAR_VPC_STACKNAME} "Zone1PublicSubnet"`}; export RADAR_VPC_PUBLICSUBNET_ZONE1
RADAR_VPC_PUBLICSUBNET_ZONE2=${RADAR_VPC_PUBLICSUBNET_ZONE2:-`get_resource ${RADAR_VPC_STACKNAME} "Zone2PublicSubnet"`}; export RADAR_VPC_PUBLICSUBNET_ZONE2
RADAR_VPC_PRIVATESUBNETS=${RADAR_VPC_PRIVATESUBNETS:-`get_vpc_subnets ${RADAR_VPC_STACKNAME} "Private"`}; export RADAR_VPC_PRIVATESUBNETS
RADAR_VPC_PRIVATESUBNET_ZONE1=${RADAR_VPC_PRIVATESUBNET_ZONE1:-`get_resource ${RADAR_VPC_STACKNAME} "Zone1PrivateSubnet"`}; export RADAR_VPC_PRIVATESUBNET_ZONE1
RADAR_VPC_PRIVATESUBNET_ZONE2=${RADAR_VPC_PRIVATESUBNET_ZONE2:-`get_resource ${RADAR_VPC_STACKNAME} "Zone2PrivateSubnet"`}; export RADAR_VPC_PRIVATESUBNET_ZONE2
RADAR_VPC_ZONES=${RADAR_VPC_ZONES:-"${RADAR_VPC_ZONE1}\\,${RADAR_VPC_ZONE2}"}; export RADAR_VPC_ZONES

#NAT template settings
##template inputs
if [[ $RADAR_COMPONENT == "nat" ]]; then
    RADAR_NAT_TEMPLATE=${RADAR_NAT_TEMPLATE:-"radar-nat-v1.json"}; export RADAR_NAT_TEMPLATE
    RADAR_NAT_ZONE1_STACKNAME=${RADAR_NAT_ZONE1_STACKNAME:-"${AWS_REGION_NORM}-${RADAR_COMPONENT}1-${RADAR_ENVIRONMENT}"}; export RADAR_NAT_ZONE1_STACKNAME
    RADAR_NAT_ZONE2_STACKNAME=${RADAR_NAT_ZONE2_STACKNAME:-"${AWS_REGION_NORM}-${RADAR_COMPONENT}2-${RADAR_ENVIRONMENT}"}; export RADAR_NAT_ZONE2_STACKNAME
    RADAR_SNS_VPC_STACKNAME=${RADAR_SNS_VPC_STACKNAME:-"${AWS_REGION_NORM}-sns-vpc-${RADAR_ENVIRONMENT}"}; export RADAR_SNS_VPC_STACKNAME
    RADAR_NAT_ZONE1=${RADAR_NAT_ZONE1:-"${RADAR_VPC_ZONE1}"}; export RADAR_NAT_ZONE1
    RADAR_NAT_ZONE2=${RADAR_NAT_ZONE2:-"${RADAR_VPC_ZONE2}"}; export RADAR_NAT_ZONE2
    RADAR_NAT_KEYNAME=${RADAR_NAT_KEYNAME:-"${AWS_KEYNAME}"}; export RADAR_NAT_KEYNAME
    RADAR_NAT_INSTANCETYPE=${RADAR_NAT_INSTANCETYPE:-"m1.small"}; export RADAR_NAT_INSTANCETYPE
    RADAR_NAT_VPC_ID=${RADAR_NAT_VPC_ID:-"${RADAR_VPC_ID}"}; export RADAR_NAT_VPC_ID
    RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID=${RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID:-`get_resource ${RADAR_VPC_STACKNAME} "Zone1PublicSubnet"`}; export RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID
    RADAR_VPC_ZONE2_PUBLIC_SUBNET_ID=${RADAR_VPC_ZONE2_PUBLIC_SUBNET_ID:-`get_resource ${RADAR_VPC_STACKNAME} "Zone2PublicSubnet"`}; export RADAR_VPC_ZONE2_PUBLIC_SUBNET_ID
    RADAR_VPC_ZONE1_PRIVATE_ROUTETABLE_ID=${RADAR_VPC_ZONE1_PRIVATE_ROUTETABLE_ID:-`get_resource ${RADAR_VPC_STACKNAME} "Zone1PrivateRouteTable"`}; export RADAR_VPC_ZONE1_PRIVATE_ROUTETABLE_ID
    RADAR_VPC_ZONE2_PRIVATE_ROUTETABLE_ID=${RADAR_VPC_ZONE2_PRIVATE_ROUTETABLE_ID:-`get_resource ${RADAR_VPC_STACKNAME} "Zone2PrivateRouteTable"`}; export RADAR_VPC_ZONE2_PRIVATE_ROUTETABLE_ID
    RADAR_NAT_SSHLOCATION=${RADAR_NAT_SSHLOCATION:-"${RADAR_VPC_SSHLOCATION}"}; export RADAR_NAT_SSHLOCATION
    RADAR_NAT_NOTICE_SNSTOPIC_ARN=${RADAR_NAT_NOTICE_SNSTOPIC_ARN:-`get_sns_topic_arn ${RADAR_SNS_VPC_STACKNAME} "Notice"`}; export RADAR_NAT_NOTICE_SNSTOPIC_ARN
    RADAR_NAT_WARNING_SNSTOPIC_ARN=${RADAR_NAT_WARNING_SNSTOPIC_ARN:-`get_sns_topic_arn ${RADAR_SNS_VPC_STACKNAME} "Warning"`}; export RADAR_NAT_WARNING_SNSTOPIC_ARN
    RADAR_NAT_CRITICAL_SNSTOPIC_ARN=${RADAR_NAT_CRITICAL_SNSTOPIC_ARN:-`get_sns_topic_arn ${RADAR_SNS_VPC_STACKNAME} "Critical"`}; export RADAR_NAT_CRITICAL_SNSTOPIC_ARN
    ##template outputs
    RADAR_NAT_BASTION_SECURITYGROUP=${RADAR_NAT_BASTION_SECURITYGROUP:-`get_resource ${RADAR_NAT_ZONE1_STACKNAME} NatSecurityGroup`}; export RADAR_NAT_BASTION_SECURITYGROUP
    RADAR_NAT_ZONE1_NATIP=${RADAR_NAT_ZONE1_NATIP:-`get_resource ${RADAR_NAT_ZONE1_STACKNAME} NatIpAddress`}; export RADAR_NAT_ZONE1_NATIP
    RADAR_NAT_ZONE2_NATIP=${RADAR_NAT_ZONE2_NATIP:-`get_resource ${RADAR_NAT_ZONE2_STACKNAME} NatIpAddress`}; export RADAR_NAT_ZONE2_NATIP
fi

#Elastic IP addresses
RADAR_EIP_TEMPLATE=${RADAR_EIP_TEMPLATE:-"radar-eip-v1.json"}; export RADAR_EIP_TEMPLATE
RADAR_EIP_STACKNAME="${AWS_REGION_NORM}-eip-${RADAR_COMPONENT}-${RADAR_ENVIRONMENT}"; export RADAR_EIP_STACKNAME

#radar template settings
##template inputs
if [[ $RADAR_COMPONENT == "radar" ]]; then
    RADAR_APP_TEMPLATE=${RADAR_APP_TEMPLATE:-"radar-app-v1.json"}; export RADAR_APP_TEMPLATE
    RADAR_APP_STACKNAME=${RADAR_APP_STACKNAME:-"${AWS_REGION_NORM}-${RADAR_COMPONENT}-app-${RADAR_ENVIRONMENT}"}; export RADAR_APP_STACKNAME
    RADAR_VPCID=${RADAR_VPCID:-"${RADAR_VPC_ID}"}; export RADAR_VPCID
    RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID=${RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID:-`get_resource ${RADAR_VPC_STACKNAME} "Zone1PublicSubnet"`}; export RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID
    #RADAR_VPC_ZONE1_PRIVATE_SUBNET_ID=${RADAR_VPC_ZONE1_PRIVATE_SUBNET_ID:-`get_resource ${RADAR_VPC_STACKNAME} "Zone1PrivateSubnet"`}; export RADAR_VPC_ZONE1_PRIVATE_SUBNET_ID
    RADAR_VPC_PRIVATE_SUBNET_IDS=${RADAR_VPC_PRIVATE_SUBNET_IDS:-`get_vpc_subnets ${RADAR_VPC_STACKNAME} "Private"`}; export RADAR_VPC_PRIVATE_SUBNET_IDS
    #due to EBS-volume restriction we only can deploy to one zone
    RADAR_ZONE=${RADAR_ZONE:-"${RADAR_VPC_ZONE1}"}; export RADAR_ZONE
    RADAR_SSHLOCATION=${RADAR_SSHLOCATION:-"${RADAR_VPC_SSHLOCATION}"}; export RADAR_SSHLOCATION
    RADAR_ROLE=${RADAR_ROLE:-"${RADAR_COMPONENT}"}; export RADAR_ROLE
    RADAR_APP_INSTANCETYPE=${RADAR_APP_INSTANCETYPE:-"t2.medium"}; export RADAR_APP_INSTANCETYPE
    RADAR_APP_ALLOCATIONID=${RADAR_APP_ALLOCATIONID:-`get_output ${RADAR_EIP_STACKNAME} AllocationId`}; export RADAR_APP_ALLOCATIONID
    RADAR_APP_BUCKET=${RADAR_APP_BUCKET:-"fieldid_dev"}; export RADAR_APP_BUCKET
    RADAR_RELEASE_BUCKET=${RADAR_RELEASE_BUCKET:-"fieldid_release"}; export RADAR_RELEASE_BUCKET
    RADAR_DEPLOY_ARTIFACT_PATH=${RADAR_DEPLOY_ARTIFACT_PATH:-"stacks/${RADAR_APP_STACKNAME}/radar-web.war"}; export RADAR_DEPLOY_ARTIFACT_PATH
    RADAR_CONNECTION_MONITOR_PATH=${RADAR_CONNECTION_MONITOR_PATH:-"stacks/${RADAR_APP_STACKNAME}/radar-connection-monitor.jar"}; export RADAR_CONNECTION_MONITOR_PATH
    RADAR_SNS_STACKNAME=${RADAR_SNS_STACKNAME:-"${AWS_REGION_NORM}-sns-${RADAR_COMPONENT}-${RADAR_ENVIRONMENT}"}; export RADAR_SNS_STACKNAME
    RADAR_NOTICE_SNSTOPIC_ARN=`get_sns_topic_arn ${RADAR_SNS_STACKNAME} "Notice"`; export RADAR_NOTICE_SNSTOPIC_ARN
    RADAR_WARNING_SNSTOPIC_ARN=`get_sns_topic_arn ${RADAR_SNS_STACKNAME} "Warning"`; export RADAR_WARNING_SNSTOPIC_ARN
    RADAR_CRITICAL_SNSTOPIC_ARN=`get_sns_topic_arn ${RADAR_SNS_STACKNAME} "Critical"`; export RADAR_CRITICAL_SNSTOPIC_ARN
fi

