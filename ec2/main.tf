terraform {
	required_providers {
		aws = {
		source = "hashicorp/aws"
		version = "~> 4.0"
		}
	}
}
provider "aws" {
	region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
	cidr_block = "172.32.0.0/16"
	tags = {
		Name = "FirstVPC"
	}
}

resource "aws_subnet" "publicsn" {
	vpc_id = aws_vpc.myvpc.id
	availability_zone = "us-east-1a"
	cidr_block = "172.32.1.0/24"
	tags = {
		name = "public subnet"
	}
}
resource "aws_subnet" "privatesn" {
	vpc_id = aws_vpc.myvpc.id
	availability_zone = "us-east-1a"
	cidr_block = "172.32.2.0/24"
	tags = {
		name = "private subnet"
	}
}

resource "aws_internet_gateway" "ig" {
	vpc_id = aws_vpc.myvpc.id
	tags = {
		Name = "Gateway"
	}
}
resource "aws_route_table" "public_route_table" {
	vpc_id = aws_vpc.myvpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.ig.id
	}
	tags = {
		Name = "Internet traffic outgoing"
	}
}
resource "aws_route_table_association" "public_ass" {
	subnet_id = aws_subnet.publicsn.id
	route_table_id = aws_route_table.public_route_table.id
}

resource "aws_key_pair" "key" {
	key_name = "MyKey"
	public_key = var.ssh_public_key
}

resource "aws_security_group" "mysg" {
	name = "mysg"
	vpc_id = aws_vpc.myvpc.id
	description = "Allow SSH Traffic"
	ingress {
		description = "Allow ssh traffic"
		to_port = 22
		from_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "public_instance" {
	ami = "ami-0715c1897453cabd1"
	instance_type = "t2.micro"
	key_name = aws_key_pair.key.key_name
	security_groups = [aws_security_group.mysg.id]
	subnet_id = aws_subnet.publicsn.id
	associate_public_ip_address = true
	ebs_block_device {
		device_name = "/dev/xvda"
		delete_on_termination = true
		volume_size = 20
		volume_type = "gp2"
	}
}

output "public_ip_address" {
	value = aws_instance.public_instance.public_ip
	description = "Public IP of instance in public subnet"
}

