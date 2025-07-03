# Find the latest Amazon Linux 2023 AMI for the bastion
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Create the bastion host using our reusable EC2 module
module "bastion_host" {
  source = "./modules/ec2-instance"

  instance_name = "${var.project_name}-bastion"
  ami_id        = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.public[0].id
  vpc_id        = aws_vpc.main.id

  additional_policy_arns = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# Allow bastion to connect to RDS on the postgres port.
# This rule connects our bastion module to the RDS instance.
resource "aws_security_group_rule" "bastion_to_rds" {
  type                     = "ingress"
  from_port                = 5432 # PostgreSQL port
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.bastion_host.security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow Bastion to connect to RDS for port forwarding"
} 