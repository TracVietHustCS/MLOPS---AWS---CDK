variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function (will be prefixed with name_prefix and environment)"
  type        = string
}

variable "source_path" {
  description = "Path to the Lambda function source code directory"
  type        = string
}


variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda function"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "VPC subnet IDs for Lambda function (optional)"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs for Lambda function (optional)"
  type        = list(string)
  default     = null
}

variable "eventbridge_rules" {
  description = "Map of EventBridge rules to trigger this Lambda function"
  type = map(object({
    description         = string
    schedule_expression = optional(string)
    event_pattern       = optional(string)
    input               = optional(string)
  }))
  default = {}
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
