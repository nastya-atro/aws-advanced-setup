# 1. Archive the code from the database directory
data "archive_file" "db_migrator_code" {
  type        = "zip"
  source_dir  = "../database"
  output_path = "${path.module}/db_migrator.zip"
}

# 2. Create an IAM role for the Lambda function
resource "aws_iam_role" "db_migrator" {
  name = "${var.project_name}-db-migrator-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach the policy for VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.db_migrator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach the policy for secret access
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

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.db_migrator.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

# 3. Security group for the Lambda function
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

# 4. The Lambda function resource
resource "aws_lambda_function" "db_migrator" {
  function_name = "${var.project_name}-db-migrator"
  handler       = "run-migrations.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.db_migrator.arn

  filename         = data.archive_file.db_migrator_code.output_path
  source_code_hash = data.archive_file.db_migrator_code.output_base64sha256

  timeout     = 300 # 5 minutes, migrations can be long-running
  memory_size = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST           = aws_db_instance.main.address
      DB_PORT           = aws_db_instance.main.port
      DB_USER           = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
      DB_NAME           = var.db_name
      # We pass the secret ARN, not the password itself, so the Lambda can securely fetch it.
      DB_CREDENTIALS_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy_attachment.secrets_access
  ]
}

# 5. Rule to allow traffic from the Lambda to the RDS instance
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432 # PostgreSQL port
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow Lambda to connect to RDS"
} 