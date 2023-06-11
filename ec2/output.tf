output "public_ip_address" {
	value = aws_instance.public_instance.public_ip
	description = "Public IP of instance in public subnet"
}
