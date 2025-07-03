output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "The private IP address of the EC2 instance."
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "The ID of the security group attached to the instance."
  value       = aws_security_group.this.id
}

output "iam_role_name" {
  description = "The name of the IAM role attached to the instance."
  value       = aws_iam_role.this.name
} 