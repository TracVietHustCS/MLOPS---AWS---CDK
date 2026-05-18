variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "model_name" {
  description = "Model name (used in resource naming)"
  type        = string
  default     = "qwen2-5-vl-7b"
}

variable "container_image" {
  description = "Container image URI"
  type        = string
}

variable "container_environment" {
  description = "Environment variables for container"
  type        = map(string)
  default     = {}
}

variable "model_s3_key" {
  description = "S3 key where model artifacts are stored"
  type        = string
  default     = "qwen2.5-vl-7b/model.tar.gz"
}

variable "model_bucket_name" {
  description = "S3 bucket name for model artifacts"
  type        = string
}

variable "model_bucket_arn" {
  description = "S3 bucket ARN for IAM policies"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM execution role for SageMaker"
  type        = string
}

variable "instance_type" {
  description = "SageMaker instance type"
  type        = string
  default     = "ml.g5.xlarge"
}

variable "initial_instance_count" {
  description = "Initial number of instances"
  type        = number
  default     = 1
}

variable "security_group_ids" {
  description = "Security group IDs for SageMaker endpoint (optional)"
  type        = list(string)
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for SageMaker endpoint"
  type        = list(string)
  default     = []
}

variable "create_endpoint" {
  description = "Create endpoint or not"
  type        = bool
  default     = false
}

variable "enable_auto_schedule" {
  description = "Enable automatic start/stop scheduling for this endpoint"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}


variable "enable_autoscaling" {
  description = "Enable autoscaling for the SageMaker endpoint"
  type        = bool
  default     = false
}

variable "min_instance_count" {
  description = "Minimum number of instances for autoscaling"
  type        = number
  default     = 1

  validation {
    condition     = var.min_instance_count > 0
    error_message = "Minimum instance count must be at least 1."
  }
}

variable "max_instance_count" {
  description = "Maximum number of instances for autoscaling"
  type        = number
  default     = 3

  validation {
    condition     = var.max_instance_count > 0
    error_message = "Maximum instance count must be at least 1."
  }
}

variable "target_invocations_per_instance" {
  description = "Target value for invocations per instance (autoscaling metric)"
  type        = number
  default     = 1000

  validation {
    condition     = var.target_invocations_per_instance > 0
    error_message = "Target invocations per instance must be greater than 0."
  }
}

variable "scale_in_cooldown" {
  description = "Cooldown period (in seconds) before scaling in"
  type        = number
  default     = 900
}

variable "scale_out_cooldown" {
  description = "Cooldown period (in seconds) before scaling out"
  type        = number
  default     = 300
}

variable "target_concurrent_requests" {
  description = "Target concurrent requests per instance for autoscaling (e.g., 10 for 10 concurrent requests)"
  type        = number
  default     = 10

  validation {
    condition     = var.target_concurrent_requests > 0
    error_message = "Target concurrent requests must be greater than 0."
  }
}