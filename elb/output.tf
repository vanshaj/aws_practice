output "public_ip_address" {
	value = "${aws_instance.private_instance.*.public_ip}"
	description = "Public IP of instance"
}
