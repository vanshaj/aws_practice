# But before this attach IAM role to the EC2 instance in the private subnet
# that allows it to access s3 
# Service name is service you want to access
# Route table is the route table that is assosciated with the Private Subnet
aws ec2 create-vpc-endpoint \
	--vpc-id vpc-0123b0057eff643cc \ 
	--service-name com.amazonaws.us-east-1.s3 \
	--route-table-id  rtb-0fe083f8c1033da4d
