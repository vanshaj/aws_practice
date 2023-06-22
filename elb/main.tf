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

resource "aws_subnet" "privatesn" {
	vpc_id = aws_vpc.myvpc.id
	availability_zone = "us-east-1a"
	cidr_block = "172.32.2.0/24"
	tags = {
		name = "private subnet"
	}
}

resource "aws_key_pair" "key" {
	key_name = "MyKey"
	public_key = var.ssh_public_key
}

resource "aws_internet_gateway" "ig" {
	vpc_id = aws_vpc.myvpc.id
	tags = {
		Name = "Gateway"
	}
}

resource "aws_route_table" "pbroutetable" {
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
	subnet_id = aws_subnet.privatesn.id
	route_table_id = aws_route_table.pbroutetable.id
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
	ingress {
		description = "Allow HTTP traffic"
		to_port = 80
		from_port = 80
		protocol = "tcp"
		cidr_blocks = ["172.32.0.0/16"]
	}
	egress {
		description = "all outgoing traffic"
		to_port = 0
		from_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "private_instance" {
	count = 2
	ami = "ami-0715c1897453cabd1"
	instance_type = "t2.micro"
	key_name = aws_key_pair.key.key_name
	security_groups = [aws_security_group.mysg.id]
	subnet_id = aws_subnet.privatesn.id
	associate_public_ip_address = true
	root_block_device {
		delete_on_termination = true
		volume_size = 8
		volume_type = "gp2"
		tags = {
			Name = "MyRootInstance"
		}
	}
	ebs_block_device {
		device_name = "/dev/sdb"
		delete_on_termination = false
		volume_size = 2
		volume_type = "gp2"
		tags = {
			Name = "MyEbsInstance"
		}
	}
	user_data = <<-EOF
	#!/bin/bash
	sudo yum update -y
	sudo yum install nginx -y
	sudo systemctl enable nginx
	sudo rm /usr/share/nginx/html/index.html
	sudo touch /usr/share/nginx/html/index.html
	sudo chmod 777 /usr/share/nginx/html/index.html
	export IP=`ifconfig | grep inet | awk 'NR==1 {print $2}'`
	sudo echo "<\!DOCTYPE html><html><head><title>My IP Address</title></head><body><h1>My IP Address</h1><p>The IP address of this machine is: $IP</p></body></html>" > /usr/share/nginx/html/index.html
	sudo service nginx restart
	EOF
}

