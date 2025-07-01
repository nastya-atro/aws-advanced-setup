output "rds_endpoint" {
  description = "The endpoint of the RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "rds_db_name" {
  description = "The name of the database in the RDS instance."
  value       = aws_db_instance.main.db_name
}

output "db_migrator_lambda_name" {
  description = "The name of the database migrator Lambda function."
  value       = aws_lambda_function.db_migrator.function_name
}

output "db_credentials_secret_arn" {
  description = "ARN of the secret containing DB credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "bastion_instance_id" {
  description = "The ID of the bastion EC2 instance for SSM."
  value       = aws_instance.bastion.id
}

output "check_service_public_ip" {
  description = "Public IP address of the check-service instance"
  value       = aws_instance.check_service.public_ip
} 