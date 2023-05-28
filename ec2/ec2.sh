 Get the VPC Id 
vpc_id=`aws ec2 describe-vpcs | jq '.Vpcs[].VpcId'`
echo $vpc_id

# Get the Subets Ids 
all_subnet_cidrs=`aws ec2 describe-subnets | jq '.Subnets[].CidrBlock'`
echo $all_subnet_cidrs

# Create a subnet in the VPC
# subnet_details=`aws ec2 create-subnet --vpc-id vpc-003074d1f1f8be3a9 --availability-zone us-east-1a --cidr-block 172.31.96.0/20 | jq `

# TODO 
# ## Create an Internet Gateway
## Copy InternetGatewayId from the output
## Update the internet-gateway-id and vpc-id in the command below:
## Create a custom route table
## Copy RouteTableId from the output
## Update the route-table-id and gateway-id in the command below:
## Check route has been created and is active
## Retrieve subnet IDs
## Update VPC ID in the command below:
## Associate subnet with custom route table to make public
## Update subnet-id and route-table-id in the command below:
## Configure subnet to issue a public IP to EC2 instances
## Update subnet-id in the command below:


# Create a key pair 
SSH_KEY_NAME="MyKeyPair"
aws ec2 create-key-pair --key-name $SSH_KEY_NAME > mykey.pem
chmod 400 mykey.pem

# Create a security group, security group is linked to VPC
SG_GROUP_NAME="my-security-group"
# here we can see that security group is bound to a VPC so we use this SG in any subnet of VPC
sg_id=`aws ec2 create-security-group --group-name $SG_GROUP_NAME --vpc-id vpc-003074d1f1f8be3a9 --description "Created Persnal SG" | jq '.GroupId'`

# Add ssh access of inbound rule
aws ec2 authorize-security-group-ingress --group-id $sg_id --group-name $SG_GROUP_NAME --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launch an Instance
# Here we can see that the EC2 instance is bound to a subnet
instance_id=`aws ec2 run-instances --image-id ami-0715c1897453cabd1 --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-05522eb73c4fe12a2 --subnet-id subnet-0d777e5ac7c0eeb71 --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp2"}}]' | jq '.Instances[0].InstanceId'`
