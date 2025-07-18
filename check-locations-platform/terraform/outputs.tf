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
  value       = module.db_migrator.name
}

output "db_credentials_secret_arn" {
  description = "ARN of the secret containing DB credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "bastion_instance_id" {
  description = "The ID of the bastion host EC2 instance."
  value       = module.bastion_host.instance_id
}

output "check_service_instance_ip" {
  description = "Public IP address of the check-service instance"
  value       = module.check_service_instance.public_ip
} 