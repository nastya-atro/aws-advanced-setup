# This file is now fully refactored to use the reusable lambda module.

# Policy for secret access - this is specific to the db_migrator and is defined here.
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "${var.project_name}-secrets-manager-policy"
  description = "Allow Lambda to read the DB secret"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "secretsmanager:GetSecretValue",
      Effect   = "Allow",
      Resource = aws_secretsmanager_secret.db_credentials.arn
    }]
  })
}

# Security group for the Lambda function, also specific to the migrator's needs.
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for the DB migrator Lambda"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic so the Lambda can access AWS APIs and the NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The Lambda function is created using the reusable module, passing in the
# specific policies and configurations it needs.
module "db_migrator" {
  source           = "./modules/lambda"
  function_name    = "${var.project_name}-db-migrator"
  handler          = "run-migrations.handler"
  runtime          = "nodejs18.x"
  filename         = "${path.root}/../artifacts/db_migrator.zip"
  source_code_hash = filebase64sha256("${path.root}/../artifacts/db_migrator.zip")
  timeout          = 300
  memory_size      = 256

  vpc_subnet_ids         = aws_subnet.private[*].id
  vpc_security_group_ids = [aws_security_group.lambda.id]

  environment_variables = {
    DB_HOST                   = aws_db_instance.main.address
    DB_PORT                   = aws_db_instance.main.port
    DB_USER                   = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
    DB_NAME                   = var.db_name
    DB_CREDENTIALS_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
  }

  additional_policy_arns = {
    secrets_manager = aws_iam_policy.secrets_manager_access.arn
  }
}

# Rule to allow traffic from the Lambda's security group to the RDS security group.
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432 # PostgreSQL port
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow Lambda to connect to RDS"
} 