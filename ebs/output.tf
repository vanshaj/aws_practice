output "ebs_id" {
	value = aws_ebs_volume.my_ebs.id
	description = "Id of ebs created"
}
