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

resource "aws_ebs_volume" "my_ebs" {
	availability_zone = "us-east-1a"
	size = "30"
	tags = { 
		Name = "MyGP3 EBS"
	}
}
