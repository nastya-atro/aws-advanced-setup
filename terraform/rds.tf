# Security group for RDS, allowing access only from within the VPC
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow traffic to RDS from within the VPC"
  vpc_id      = aws_vpc.main.id

  # Rules will be added in lambda.tf to allow access from the Lambda function
  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# Subnet group for RDS. The DB will be placed in our private subnets.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# The main resource - a PostgreSQL DB instance
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "15.7"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  
  db_name              = var.db_name
  username             = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
  password             = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
  
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Important settings for security and management
  publicly_accessible = false
  skip_final_snapshot = true # For production, set this to false
  multi_az            = false # For production, set this to true for high availability

  tags = {
    Name = "${var.project_name}-db-instance"
  }
} 