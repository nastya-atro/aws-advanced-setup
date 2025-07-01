# This file contains the resources for the check-service EC2 instance.

# 1. Archive the check-service application code
data "archive_file" "check_service_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../check-service"
  output_path = "${path.module}/check_service.zip"
}

# 2. Create an S3 bucket to store the application code
resource "aws_s3_bucket" "check_service_code" {
  bucket = "${var.project_name}-check-service-code-bucket"
  
  tags = {
    Name = "${var.project_name}-check-service-code"
  }
}

# 3. Upload the zipped code to the S3 bucket
resource "aws_s3_object" "check_service_code" {
  bucket = aws_s3_bucket.check_service_code.id
  key    = "check_service.zip"
  source = data.archive_file.check_service_zip.output_path
  etag   = filemd5(data.archive_file.check_service_zip.output_path)
}

# 4. IAM role for the check-service instance
resource "aws_iam_role" "check_service" {
  name = "${var.project_name}-check-service-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# 5. IAM policy to allow reading from the S3 bucket
resource "aws_iam_policy" "check_service_s3" {
  name        = "${var.project_name}-check-service-s3-policy"
  description = "Allows reading the check-service code from S3"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "s3:GetObject",
        Effect   = "Allow",
        Resource = "arn:aws:s3:::${aws_s3_bucket.check_service_code.id}/*"
      }
    ]
  })
}

# 6. Attach policies to the role
resource "aws_iam_role_policy_attachment" "check_service_s3" {
  role       = aws_iam_role.check_service.name
  policy_arn = aws_iam_policy.check_service_s3.arn
}

resource "aws_iam_role_policy_attachment" "check_service_ssm" {
  role       = aws_iam_role.check_service.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 7. Instance profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "check_service" {
  name = "${var.project_name}-check-service-profile"
  role = aws_iam_role.check_service.name
}

# 8. Security group for the check-service instance
resource "aws_security_group" "check_service" {
  name   = "${var.project_name}-check-service-sg"
  vpc_id = aws_vpc.main.id
  
  description = "Allow inbound traffic for check-service and all outbound"

  # Allow inbound HTTP traffic on port 3002
  ingress {
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-check-service-sg"
  }
}

# 9. The EC2 instance for the check-service
resource "aws_instance" "check_service" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  
  subnet_id     = aws_subnet.public[0].id
  
  vpc_security_group_ids = [aws_security_group.check_service.id]
  iam_instance_profile   = aws_iam_instance_profile.check_service.name

  # User data script to provision the instance
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker unzip
              
              systemctl start docker
              systemctl enable docker
              
              # Add ec2-user to the docker group so you can execute Docker commands without sudo
              usermod -a -G docker ec2-user
              
              # Download the service code from S3
              aws s3 cp s3://${aws_s3_bucket.check_service_code.id}/check_service.zip /home/ec2-user/check_service.zip
              
              # Unzip and set up the service
              cd /home/ec2-user
              unzip check_service.zip -d check-service
              
              cd /home/ec2-user/check-service
              
              # Build and run the Docker container
              docker build -t check-service .
              docker run -d -p 3002:3002 --restart always -e CHECK_SERVICE_API_KEY='${var.check_service_api_key}' --name check-service-container check-service
              EOF

  tags = {
    Name = "${var.project_name}-check-service-host"
  }
} 