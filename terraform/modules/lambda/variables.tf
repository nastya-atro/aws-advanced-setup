variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The handler for the Lambda function."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "The runtime for the Lambda function."
  type        = string
  default     = "nodejs20.x"
}

variable "source_code_path" {
  description = "The path to the source code directory for the Lambda function."
  type        = string
}

variable "timeout" {
  description = "The timeout for the Lambda function in seconds."
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "The memory size for the Lambda function in MB."
  type        = number
  default     = 128
}

variable "iam_policy_document" {
  description = "An additional IAM policy document to attach to the Lambda role."
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "A map of environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs associated with the Lambda function."
  type        = list(string)
  default     = []
} 