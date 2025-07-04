# This file contains the resources for the check-service EC2 instance.

locals {
  check_service_zip_hash = filemd5("${path.root}/../artifacts/check_service.zip")
}

# 1. Create an S3 bucket to store the application code
resource "aws_s3_bucket" "check_service_code" {
  bucket = "${var.project_name}-check-service-code-bucket"
}

# 2. Upload the zipped code to the S3 bucket
resource "aws_s3_object" "check_service_code" {
  bucket = aws_s3_bucket.check_service_code.id
  key    = "check_service.zip"
  source = "${path.root}/../artifacts/check_service.zip"
  etag   = local.check_service_zip_hash
}

# 3. IAM policy to allow reading from the S3 bucket
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

# 4. IAM policy to allow starting the step function execution
resource "aws_iam_policy" "check_service_sfn" {
  name        = "${var.project_name}-check-service-sfn-policy"
  description = "Allows starting and describing step function executions"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        # This statement allows the service to start the workflow.
        Action   = "states:StartExecution",
        Effect   = "Allow",
        Resource = aws_sfn_state_machine.on_demand_check_workflow.id
      },
      {
        # This statement allows the service to check the status of any execution
        # belonging to the specified state machine.
        Action   = "states:DescribeExecution",
        Effect   = "Allow",
        Resource = "${replace(aws_sfn_state_machine.on_demand_check_workflow.id, "stateMachine", "execution")}:*"
      }
    ]
  })
}

# 5. The EC2 instance for the check-service, using our module
module "check_service_instance" {
  source = "./modules/ec2-instance"

  instance_name = "${var.project_name}-check-service"
  ami_id        = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  vpc_id        = aws_vpc.main.id

  additional_policy_arns = {
    s3_read   = aws_iam_policy.check_service_s3.arn
    sfn_start = aws_iam_policy.check_service_sfn.arn
    ssm       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  ingress_rules = [
    {
      description = "Allow HTTP traffic from anywhere"
      from_port   = 3002
      to_port     = 3002
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  user_data = nonsensitive(<<-EOF
              #!/bin/bash
              # This hash changes when the artifact changes, forcing a new instance
              #
              # Hash: ${local.check_service_zip_hash}

              yum update -y
              yum install -y docker unzip
              
              systemctl start docker
              systemctl enable docker
              
              usermod -a -G docker ec2-user
              
              aws s3 cp s3://${aws_s3_bucket.check_service_code.id}/check_service.zip /home/ec2-user/check_service.zip
              
              cd /home/ec2-user
              # Clean up previous deployment
              rm -rf check-service
              unzip check_service.zip -d check-service
              
              cd /home/ec2-user/check-service
              
              # Stop and remove old container if it exists to avoid name conflicts
              docker stop check-service-container || true
              docker rm check-service-container || true
              
              docker build -t check-service .
              docker run -d -p 3002:3002 --restart always \
                -e CHECK_SERVICE_API_KEY='${var.check_service_api_key}' \
                -e STEP_FUNCTION_ARN='${aws_sfn_state_machine.on_demand_check_workflow.id}' \
                -e AWS_REGION='${data.aws_region.current.name}' \
                --name check-service-container check-service
              EOF
  )

  tags = {
    Name = "${var.project_name}-check-service"
  }
} 