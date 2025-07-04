# IAM role that allows services to manage our instance (e.g., SSM)
resource "aws_iam_role" "this" {
  name = "${var.instance_name}-role"
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
  tags = var.tags
}

# Attach any additional policies provided
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = var.additional_policy_arns
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# The instance profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "this" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.this.name
  # tags isn't a valid argument for aws_iam_instance_profile, so we omit it here.
}

# Security group for the instance
resource "aws_security_group" "this" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} instance"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = lookup(ingress.value, "description", null)
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = lookup(egress.value, "description", null)
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = lookup(egress.value, "cidr_blocks", null)
    }
  }

  tags = var.tags
}

# The EC2 instance itself
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name

  user_data                   = var.user_data
  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name = var.instance_name
  })
} 