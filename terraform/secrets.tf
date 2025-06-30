# Generate a random and secure password for the DB
resource "random_password" "db_password" {
  length  = 20
  special = true
  # PostgreSQL does not like some characters, so we exclude them.
  override_special = "!#$%&()*+,-.:;<=>?@[]^_`{|}~"
}

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/db-credentials"
  description = "Credentials for the RDS PostgreSQL database"
}

# Write a secret version with the username and generated password
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
} 