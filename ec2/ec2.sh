 Get the VPC Id 
default_vpc_id=`aws ec2 describe-vpcs | jq '.Vpcs[].VpcId'`
echo "Default Vpc Id is $default_vpc_id"

vpc_id=`aws ec2 create-vpc \
	--cidr-block 172.32.0.0/16 \
	--tag-specification '[{"ResourceType": "vpc", "Tags": [{"Key": "Name", "Value": "FirstVPC"}]}]' \
	--instance-tenancy default | jq '.Vpc.VpcId' | tr -d '"'`
echo "newly created vpc id is $vpc_id"

# Get the Subets Ids 
all_subnet_cidrs=`aws ec2 describe-subnets | jq '.Subnets[].CidrBlock'`
echo $all_subnet_cidrs

# Create a public subnet in the VPC inside a specific AZ
subnet_id=`aws ec2 create-subnet \
	--vpc-id $vpc_id \
	--availability-zone us-east-1a \
	--cidr-block 172.32.1.0/24 | jq '.Subnet.SubnetId' | tr -d '"'`
echo "Created new public subnet with id $subnet_id"
subnet_id_pvt=`aws ec2 create-subnet \
		--vpc-id $vpc_id \
		--availability-zone us-east-1a \
		--cidr-block 172.32.2.0/24 | jq '.Subnet.SubnetId' | tr -d '"'`
echo "Created new private subnet with id $subnet_id"

# Create an Internet Gateway
ig_id=`aws ec2 create-internet-gateway \
	--tag-specification '[{"ResourceType": "internet-gateway", "Tags": [{"Key": "Name", "Value": "IG-1"}]}]' | jq '.InternetGateway.InternetGatewayId' | tr -d '"'`
# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
	--internet-gateway-id $ig_id \
	--vpc-id $vpc_id

# Create a custom route table inside vpc but no assosciation with the subnets
route_table_id=`aws ec2 create-route-table \
		--vpc-id $vpc_id | jq '.RouteTable.RouteTableId' | tr -d '"'`
echo "Created route table"
# Create a route for the route table
aws ec2 create-route \
	--route-table-id $route_table_id \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $ig_id
echo "Created routes for route table"
# Assosciate the route table to the public subnet
aws ec2 associate-route-table \
	--route-table-id $route_table_id \
	--subnet-id  $subnet_id
echo "Assosciated the route table to public subnet"

# Create a key pair 
SSH_KEY_NAME="MyKeyPair"
aws ec2 create-key-pair \
	--key-name $SSH_KEY_NAME > mykey.pem
# Update the SSH key to only contain content
chmod 400 mykey.pem
echo "Create ssh key"

# Create a security group, security group is linked to VPC
SG_GROUP_NAME="my-security-group"
# here we can see that security group is bound to a VPC so we use this SG in any subnet of VPC
sg_id=`aws ec2 create-security-group \
	--group-name $SG_GROUP_NAME \
	--vpc-id $vpc_id \
	--description "Created Persnal SG" | jq '.GroupId' | tr -d '"'`
echo "Created security group $SG_GROUP_NAME"
# Add ssh access of inbound rule
aws ec2 authorize-security-group-ingress \
	--group-id $sg_id \
	--group-name $SG_GROUP_NAME \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0
echo "Add ingress rule in security group"

# Launch an Instance
# Here we can see that the EC2 instance is bound to a subnet
instance_id=`aws ec2 run-instances \
	--image-id ami-0715c1897453cabd1 \
	--count 1 --instance-type t2.micro --key-name MyKeyPair \
	--security-group-ids $sg_id \
	--subnet-id $subnet_id \
	--associate-public-ip-address \
	--block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp2"}}]' | jq '.Instances[0].InstanceId' | tr -d '"'`
echo "Created instance $instance_id"

# Create an elastic IP
elastic_ip=`aws ec2 allocate-address\
	--domain vpc | jq '.AllocationId' | tr -d '"'`
# Create a Nat gateway and associate the IP
ng_id=`aws ec2 create-nat-gateway \
	--subnet-id $subnet_id \
	--allocation-id $elastic_ip | jq '.NatGateway.NatGatewayId' | tr -d '"'`
# Create a route table
route_table_id_pvt=`aws ec2 create-route-table \
		--vpc-id $vpc_id | jq '.RouteTable.RouteTableId' | tr -d '"'`
# Create a route for the route table
aws ec2 create-route \
	--route-table-id $route_table_id_pvt \
	--destination-cidr-block 0.0.0.0/0 \
	--nat-gateway-id $ng_id
echo "Created routes for route table"
# Assosciate the route table to the public subnet
association_route_id=`aws ec2 associate-route-table \
	--route-table-id $route_table_id_pvt \
	--subnet-id  $subnet_id_pvt | jq `
echo "Assosciated the route table to public subnet"

# Create a ec2 instance in private subnet and it will be able to access internet now
instance_id_pvt=`aws ec2 run-instances \
		--image-id ami-0715c1897453cabd1 \
		--count 1 --instance-type t2.micro --key-name MyKeyPair \
		--security-group-id $sg_id \
		--subnet-id $subnet_id_pvt \
		--block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp2"}}]' | jq '.Instances[0].InstanceId' | tr -d '"'`
echo "Created instance in pvt subnet"
