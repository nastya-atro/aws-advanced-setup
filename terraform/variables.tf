variable "aws_region" {
  description = "The AWS region to deploy all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A name for the project to prefix resources."
  type        = string
  default     = "adv-setup"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "The name for the PostgreSQL database."
  type        = string
  default     = "checkservicedb"
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
  default     = "masteruser"
} 