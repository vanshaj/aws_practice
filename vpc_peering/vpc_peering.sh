vpc_id=`aws ec2 create-vpc \
        --cidr-block 172.16.32.0/19 \
        --tag-specification '[{"ResourceType": "vpc", "Tags": [{"Key": "Name", "Value": "FirstVPC"}]}]' \
        --instance-tenancy default | jq '.Vpc.VpcId' | tr -d '"'`
echo "newly created vpc id is $vpc_id"
vpc_id_2=`aws ec2 create-vpc \
        --cidr-block 172.16.64.0/19 \
        --tag-specification '[{"ResourceType": "vpc", "Tags": [{"Key": "Name", "Value": "SecondVPC"}]}]' \
        --instance-tenancy default | jq '.Vpc.VpcId' | tr -d '"'`
echo "newly created vpc id is $vpc_id_2"
# Create VPC peering connection
vpc_conn_id=`aws ec2 create-vpc-peering-connection \
	--vpc-id $vpc_id \
	--peer-vpc-id $vpc_id_2 | jq '.VpcPeeringConnection.VpcPeeringConnectionId' | tr -d '"'`
# Accept the vpc peering request
aws ec2 accept-vpc-peering-connection \
	--vpc-peering-connection-id $vpc_conn_id

# Create a public subnet in fist VPC
subnet_id=`aws ec2 create-subnet \
        --vpc-id $vpc_id \
        --availability-zone us-east-1a \
        --cidr-block 172.16.32.0/24 | jq '.Subnet.SubnetId' | tr -d '"'`
echo "Created new public subnet with id $subnet_id"
# Create a internet gateway
ig_id=`aws ec2 create-internet-gateway \
        --tag-specification '[{"ResourceType": "internet-gateway", "Tags": [{"Key": "Name", "Value": "IG-1"}]}]' | jq '.InternetGateway.InternetGatewayId' | tr -d '"'`
# Attach it to first VPC
aws ec2 attach-internet-gateway \
        --internet-gateway-id $ig_id \
        --vpc-id $vpc_id
# Create a route table in first VPC
route_table_id=`aws ec2 create-route-table \
                --vpc-id $vpc_id | jq '.RouteTable.RouteTableId' | tr -d '"'`
echo "Created route table"
# Create route for internet gateway
aws ec2 create-route \
        --route-table-id $route_table_id \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id $ig_id
# Create route for VPC peering
aws ec2 create-route \
	--route-table-id $route_table_id \
	--destination-cidr-block 172.16.64.0/19 \
	--vpc-peering-connection-id $vpc_conn_id
# Assosciate the route table to the subnet
aws ec2 associate-route-table \
        --route-table-id $route_table_id \
        --subnet-id  $subnet_id

# Ceate a public subnet in second VPC
subnet_id_2=`aws ec2 create-subnet \
	--vpc-id $vpc_id_2 \
        --availability-zone us-east-1a \
	--cidr-block 172.16.64.0/24 | jq '.Subnet.SubnetId' | tr -d '"'`
# Create a route table 
route_table_id_2=`aws ec2 create-route-table \
	--vpc-id $vpc_id_2 | jq '.RouteTable.RouteTableId' | tr -d '"'`
# Create routes 
aws ec2 create-route \
	--route-table-id $route_table_id_2 \
	--destination-cidr-block 172.16.32.0/19 \
	--vpc-peering-connection-id $vpc_conn_id
aws ec2 associate-route-table \
	--route-table-id $route_table_id_2 \
	--subnet-id $subnet_id_2
