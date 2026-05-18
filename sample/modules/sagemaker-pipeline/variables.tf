variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "pipeline_name" {
  description = "Name of the SageMaker pipeline"
  type        = string
}

variable "pipeline_display_name" {
  description = "Display name for the pipeline (defaults to pipeline_name if not specified)"
  type        = string
  default     = null
}

variable "role_arn" {
  description = "ARN of the IAM role for the pipeline execution"
  type        = string
}

variable "pipeline_definition_s3_bucket" {
  description = "S3 bucket containing the pipeline definition JSON"
  type        = string
  default     = null
}

variable "pipeline_definition_s3_key" {
  description = "S3 object key for the pipeline definition JSON"
  type        = string
  default     = null
}

variable "pipeline_definition_body" {
  description = "Pipeline definition as JSON string (alternative to S3 location)"
  type        = string
  default     = null

  validation {
    condition     = var.pipeline_definition_body == null || can(jsondecode(var.pipeline_definition_body))
    error_message = "pipeline_definition_body must be a valid JSON string."
  }
}

variable "max_parallel_execution_steps" {
  description = "Maximum number of steps that can run in parallel"
  type        = number
  default     = null

  validation {
    condition     = var.max_parallel_execution_steps == null || var.max_parallel_execution_steps > 0
    error_message = "max_parallel_execution_steps must be greater than 0."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for pipeline execution (used by pipeline steps)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for pipeline execution (used by pipeline steps)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
