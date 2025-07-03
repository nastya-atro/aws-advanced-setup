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

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem."
  type        = string
}

variable "source_code_hash" {
  description = "Used to trigger updates when the deployment package changes."
  type        = string
}

variable "timeout" {
  description = "The timeout for the Lambda function in seconds."
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "The amount of memory that your function has access to."
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

variable "additional_policy_arns" {
  description = "Map of additional IAM policy ARNs to attach to the function's role. Keys are static names, values are policy ARNs."
  type        = map(string)
  default     = {}
} 