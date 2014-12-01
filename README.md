radar-deploy
============
Testing AWS OpsWorks 


#Provisioning AWS resources

## Prerequisites
brew install awscli jq

## SNS Topics
SNS is used by components to report operational issues. These topics are
created only once and subscriptions are managed thru the aws console.
(note: After you create an Amazon SNS topic, you cannot update its properties
by using AWS CloudFormation. You can modify an Amazon SNS topic by using the
AWS Management Console.)
### Create SNS topics
```bash
export RADAR_ENVIRONMENT=dev;
for RADAR_COMPONENT in vpc nat radar
do
    export RADAR_COMPONENT;
    source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
    source ./envconfig/default-params.sh;

    find . -name ${RADAR_SNS_TEMPLATE} -type f -exec \
        aws cloudformation create-stack \
          --region ${AWS_REGION} \
          --stack-name ${RADAR_SNS_STACKNAME} \
          --template-body file://{} \
          --parameters \
            ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
            ParameterKey=Component,ParameterValue=${RADAR_COMPONENT} \
          \;
done
```

## VPC stack
### Create VPC stack
```bash
export RADAR_ENVIRONMENT=dev;
export RADAR_COMPONENT=vpc;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

find . -name ${RADAR_VPC_TEMPLATE} -type f -exec \
    aws cloudformation create-stack \
      --region ${AWS_REGION} \
      --stack-name ${RADAR_VPC_STACKNAME} \
      --template-body file://{} \
      --parameters \
        ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
        ParameterKey=Zone1,ParameterValue=${RADAR_VPC_ZONE1} \
        ParameterKey=Zone2,ParameterValue=${RADAR_VPC_ZONE2} \
      \;
```


### Update deployed VPC stack
```bash
export RADAR_ENVIRONMENT=dev;
export RADAR_COMPONENT=vpc;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

find . -name ${RADAR_VPC_TEMPLATE} -type f -exec \
    aws cloudformation update-stack \
      --region ${AWS_REGION} \
      --stack-name ${RADAR_VPC_STACKNAME} \
      --template-body file://{} \
      --parameters \
        ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
        ParameterKey=Zone1,ParameterValue=${RADAR_VPC_ZONE1} \
        ParameterKey=Zone2,ParameterValue=${RADAR_VPC_ZONE2} \
      \;
```

## NAT Device/Bastion Host stack
### Create NAT Device in zone1
```bash
export RADAR_ENVIRONMENT=dev;
export RADAR_COMPONENT=nat;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

find . -name ${RADAR_NAT_TEMPLATE} -type f -exec \
    aws cloudformation create-stack \
      --region ${AWS_REGION} \
      --stack-name ${RADAR_NAT_ZONE1_STACKNAME} \
      --template-body file://{} \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
        ParameterKey=KeyName,ParameterValue=${RADAR_NAT_KEYNAME} \
        ParameterKey=NatInstanceType,ParameterValue=${RADAR_NAT_INSTANCETYPE} \
        ParameterKey=VpcId,ParameterValue=${RADAR_NAT_VPC_ID} \
        ParameterKey=SshLocation,ParameterValue=\'${RADAR_NAT_SSHLOCATION}\' \
        ParameterKey=NoticeSnsTopicArn,ParameterValue=\'${RADAR_NAT_NOTICE_SNSTOPIC_ARN}\' \
        ParameterKey=WarningSnsTopicArn,ParameterValue=\'${RADAR_NAT_WARNING_SNSTOPIC_ARN}\' \
        ParameterKey=CriticalSnsTopicArn,ParameterValue=\'${RADAR_NAT_CRITICAL_SNSTOPIC_ARN}\' \
        ParameterKey=PublicSubnetId,ParameterValue=\'${RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID}\' \
        ParameterKey=PrivateRouteTableId,ParameterValue=\'${RADAR_VPC_ZONE1_PRIVATE_ROUTETABLE_ID}\' \
        ParameterKey=Zone,ParameterValue=\'${RADAR_NAT_ZONE1}\' \
      \;
```

### Update NAT Device in zone1
```bash
export RADAR_ENVIRONMENT=dev;
export RADAR_COMPONENT=nat;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

find . -name ${RADAR_NAT_TEMPLATE} -type f -exec \
    aws cloudformation update-stack \
      --region ${AWS_REGION} \
      --stack-name ${RADAR_NAT_ZONE1_STACKNAME} \
      --template-body file://{} \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
        ParameterKey=KeyName,ParameterValue=${RADAR_NAT_KEYNAME} \
        ParameterKey=NatInstanceType,ParameterValue=${RADAR_NAT_INSTANCETYPE} \
        ParameterKey=VpcId,ParameterValue=${RADAR_NAT_VPC_ID} \
        ParameterKey=SshLocation,ParameterValue=\'${RADAR_NAT_SSHLOCATION}\' \
        ParameterKey=NoticeSnsTopicArn,ParameterValue=\'${RADAR_NAT_NOTICE_SNSTOPIC_ARN}\' \
        ParameterKey=WarningSnsTopicArn,ParameterValue=\'${RADAR_NAT_WARNING_SNSTOPIC_ARN}\' \
        ParameterKey=CriticalSnsTopicArn,ParameterValue=\'${RADAR_NAT_CRITICAL_SNSTOPIC_ARN}\' \
        ParameterKey=PublicSubnetId,ParameterValue=\'${RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID}\' \
        ParameterKey=PrivateRouteTableId,ParameterValue=\'${RADAR_VPC_ZONE1_PRIVATE_ROUTETABLE_ID}\' \
        ParameterKey=Zone,ParameterValue=\'${RADAR_NAT_ZONE1}\' \
      \;
```

## Elastic IP addresses
### Create EIPs
```bash
export RADAR_ENVIRONMENT=dev;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

for RADAR_COMPONENT in web mobile
do
    export RADAR_COMPONENT;
    source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
    source ./envconfig/default-params.sh;

    find . -name ${RADAR_EIP_TEMPLATE} -type f -exec \
        aws cloudformation create-stack \
          --region ${AWS_REGION} \
          --stack-name ${RADAR_EIP_STACKNAME} \
          --template-body file://{} \
          \;
done
```

## Radar stack
### Create Radar application stack
```bash
export RADAR_ENVIRONMENT=dev;
export RADAR_COMPONENT=mobile;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

find . -name ${RADAR_APP_TEMPLATE} -type f -exec \
    aws cloudformation create-stack \
      --region ${AWS_REGION} \
      --stack-name ${RADAR_APP_STACKNAME} \
      --template-body file://{} \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
        ParameterKey=KeyName,ParameterValue=${AWS_KEYNAME} \
        ParameterKey=VpcId,ParameterValue=${RADAR_VPCID} \
        ParameterKey=PublicSubnetId,ParameterValue=\'${RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID}\' \
        ParameterKey=Zone,ParameterValue=\'${RADAR_ZONE}\' \
        ParameterKey=SshLocation,ParameterValue=${RADAR_SSHLOCATION} \
        ParameterKey=RadarRole,ParameterValue=${RADAR_ROLE} \
        ParameterKey=RadarAppInstanceType,ParameterValue=${RADAR_APP_INSTANCETYPE} \
        ParameterKey=RadarAppAllocationId,ParameterValue=${RADAR_APP_ALLOCATIONID} \
        ParameterKey=RadarAppBucket,ParameterValue=${RADAR_APP_BUCKET} \
        ParameterKey=RadarDbName,ParameterValue=${RADAR_DB_NAME} \
        ParameterKey=RadarDbAddress,ParameterValue=${RADAR_DB_ADDRESS} \
        ParameterKey=RadarDbPort,ParameterValue=${RADAR_DB_PORT} \
        ParameterKey=RadarDbUser,ParameterValue=${RADAR_DB_USER} \
        ParameterKey=RadarDbPassword,ParameterValue=${RADAR_DB_PASSWORD} \
        ParameterKey=ReleaseBucket,ParameterValue=${RADAR_RELEASE_BUCKET} \
        ParameterKey=DeployArtifactPath,ParameterValue=${RADAR_DEPLOY_ARTIFACT_PATH} \
        ParameterKey=ConnectionMonitorArtifactPath,ParameterValue=${RADAR_CONNECTION_MONITOR_PATH} \
        ParameterKey=NoticeSnsTopicArn,ParameterValue=\'${RADAR_NOTICE_SNSTOPIC_ARN}\' \
        ParameterKey=WarningSnsTopicArn,ParameterValue=\'${RADAR_WARNING_SNSTOPIC_ARN}\' \
        ParameterKey=CriticalSnsTopicArn,ParameterValue=\'${RADAR_CRITICAL_SNSTOPIC_ARN}\' \
      --disable-rollback \
      \;
```

### Update Radar application stack
```bash
export RADAR_ENVIRONMENT=dev;
export RADAR_COMPONENT=mobile;
source ./envconfig/${RADAR_ENVIRONMENT}-params.sh;
source ./envconfig/default-params.sh

find . -name ${RADAR_TEMPLATE} -type f -exec \
    aws cloudformation update-stack \
      --region ${AWS_REGION} \
      --stack-name ${RADAR_STACKNAME} \
      --template-body file://{} \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey=Environment,ParameterValue=${RADAR_ENVIRONMENT} \
        ParameterKey=KeyName,ParameterValue=${AWS_KEYNAME} \
        ParameterKey=VpcId,ParameterValue=${RADAR_VPCID} \
        ParameterKey=PublicSubnetId,ParameterValue=\'${RADAR_VPC_ZONE1_PUBLIC_SUBNET_ID}\' \
        ParameterKey=Zone,ParameterValue=\'${RADAR_ZONE}\' \
        ParameterKey=SshLocation,ParameterValue=${RADAR_SSHLOCATION} \
        ParameterKey=RadarRole,ParameterValue=${RADAR_ROLE} \
        ParameterKey=RadarAppInstanceType,ParameterValue=${RADAR_APP_INSTANCETYPE} \
        ParameterKey=RadarAppAllocationId,ParameterValue=${RADAR_APP_ALLOCATIONID} \
        ParameterKey=RadarAppBucket,ParameterValue=${RADAR_APP_BUCKET} \
        ParameterKey=RadarDbName,ParameterValue=${RADAR_DB_NAME} \
        ParameterKey=RadarDbAddress,ParameterValue=${RADAR_DB_ADDRESS} \
        ParameterKey=RadarDbPort,ParameterValue=${RADAR_DB_PORT} \
        ParameterKey=RadarDbUser,ParameterValue=${RADAR_DB_USER} \
        ParameterKey=RadarDbPassword,ParameterValue=${RADAR_DB_PASSWORD} \
        ParameterKey=ReleaseBucket,ParameterValue=${RADAR_RELEASE_BUCKET} \
        ParameterKey=DeployArtifactPath,ParameterValue=${RADAR_DEPLOY_ARTIFACT_PATH} \
        ParameterKey=ConnectionMonitorArtifactPath,ParameterValue=${RADAR_CONNECTION_MONITOR_PATH} \
        ParameterKey=NoticeSnsTopicArn,ParameterValue=\'${RADAR_NOTICE_SNSTOPIC_ARN}\' \
        ParameterKey=WarningSnsTopicArn,ParameterValue=\'${RADAR_WARNING_SNSTOPIC_ARN}\' \
        ParameterKey=CriticalSnsTopicArn,ParameterValue=\'${RADAR_CRITICAL_SNSTOPIC_ARN}\' \
      \;
```
