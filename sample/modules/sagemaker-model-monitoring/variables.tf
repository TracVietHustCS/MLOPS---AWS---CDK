variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "monitoring_job_name" {
  description = "Name for the monitoring job definition"
  type        = string
  default     = "data-quality"
}

variable "endpoint_name" {
  description = "Name of the SageMaker endpoint to monitor"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role for the monitoring job"
  type        = string
}

# Schedule configuration
variable "schedule_expression" {
  description = "Cron expression for the monitoring schedule (e.g., 'cron(0 * ? * * *)')"
  type        = string
  default     = "cron(0 * ? * * *)"
}

variable "create_monitoring_schedule" {
  description = "Whether to create the monitoring schedule"
  type        = bool
  default     = true
}

# Output configuration
variable "output_s3_uri" {
  description = "S3 URI for monitoring output results"
  type        = string
}

variable "output_local_path" {
  description = "Local path for monitoring output"
  type        = string
  default     = "/opt/ml/processing/output"
}

variable "s3_upload_mode" {
  description = "S3 upload mode (Continuous or EndOfJob)"
  type        = string
  default     = "EndOfJob"

  validation {
    condition     = contains(["Continuous", "EndOfJob"], var.s3_upload_mode)
    error_message = "s3_upload_mode must be either 'Continuous' or 'EndOfJob'."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting monitoring output"
  type        = string
  default     = null
}

# Input configuration
variable "input_local_path" {
  description = "Local path for endpoint input data"
  type        = string
  default     = "/opt/ml/processing/input/endpoint"
}

variable "s3_data_distribution_type" {
  description = "S3 data distribution type (FullyReplicated or ShardedByS3Key)"
  type        = string
  default     = "FullyReplicated"

  validation {
    condition     = contains(["FullyReplicated", "ShardedByS3Key"], var.s3_data_distribution_type)
    error_message = "s3_data_distribution_type must be either 'FullyReplicated' or 'ShardedByS3Key'."
  }
}

variable "s3_input_mode" {
  description = "S3 input mode (Pipe or File)"
  type        = string
  default     = "File"

  validation {
    condition     = contains(["Pipe", "File"], var.s3_input_mode)
    error_message = "s3_input_mode must be either 'Pipe' or 'File'."
  }
}

# Instance configuration
variable "instance_type" {
  description = "Instance type for the monitoring job"
  type        = string
  default     = "ml.m5.large"
}

variable "instance_count" {
  description = "Number of instances for the monitoring job"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0
    error_message = "instance_count must be at least 1."
  }
}

variable "volume_size_in_gb" {
  description = "Size of the EBS volume attached to the monitoring instance (in GB)"
  type        = number
  default     = 20

  validation {
    condition     = var.volume_size_in_gb >= 1
    error_message = "volume_size_in_gb must be at least 1 GB."
  }
}

variable "volume_kms_key_id" {
  description = "KMS key ID for encrypting the EBS volume"
  type        = string
  default     = null
}

# Network configuration
variable "subnet_ids" {
  description = "Subnet IDs for the monitoring job VPC configuration"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for the monitoring job VPC configuration"
  type        = list(string)
  default     = []
}

variable "enable_inter_container_traffic_encryption" {
  description = "Enable encryption for inter-container traffic"
  type        = bool
  default     = true
}

variable "enable_network_isolation" {
  description = "Enable network isolation for the monitoring job"
  type        = bool
  default     = false
}

# Container configuration
variable "custom_image_uri" {
  description = "Custom container image URI (defaults to SageMaker Model Monitor image)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the monitoring container"
  type        = map(string)
  default     = {}
}

# Stopping condition
variable "max_runtime_in_seconds" {
  description = "Maximum runtime for the monitoring job in seconds"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_runtime_in_seconds == null || var.max_runtime_in_seconds > 0
    error_message = "max_runtime_in_seconds must be greater than 0."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
