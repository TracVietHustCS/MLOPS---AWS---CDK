# =============================================================================
# SageMaker Training Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------
variable "sagemaker_role_arn" {
  description = "SageMaker execution role ARN"
  type        = string
}

variable "execution_role_arn" {
  description = "Step Functions execution role ARN (if null, creates new role)"
  type        = string
  default     = null
}

variable "permissions_boundary" {
  description = "IAM permissions boundary ARN"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Training Configuration
# -----------------------------------------------------------------------------
variable "training_image" {
  description = "Docker image URI for training"
  type        = string
}

variable "inference_image" {
  description = "Docker image URI for inference (if different from training)"
  type        = string
  default     = null
}

variable "training_input_mode" {
  description = "Training input mode (File or Pipe)"
  type        = string
  default     = "File"
}

variable "training_data_content_type" {
  description = "Content type of training data"
  type        = string
  default     = "text/csv"
}

variable "training_instance_type" {
  description = "Instance type for training"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "training_instance_count" {
  description = "Number of training instances"
  type        = number
  default     = 1
}

variable "training_volume_size" {
  description = "EBS volume size in GB for training"
  type        = number
  default     = 50
}

variable "max_runtime_seconds" {
  description = "Maximum training runtime in seconds"
  type        = number
  default     = 86400 # 24 hours
}

variable "hyperparameters" {
  description = "Hyperparameters for training"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Output Configuration
# -----------------------------------------------------------------------------
variable "output_bucket" {
  description = "S3 bucket for model artifacts"
  type        = string
}

variable "output_prefix" {
  description = "S3 prefix for model artifacts"
  type        = string
  default     = "model-artifacts"
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------
variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "vpc_config" {
  description = "VPC configuration for training"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "enable_network_isolation" {
  description = "Enable network isolation for training"
  type        = bool
  default     = false
}

variable "enable_inter_container_encryption" {
  description = "Enable inter-container traffic encryption"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Scheduled Training
# -----------------------------------------------------------------------------
variable "enable_scheduled_training" {
  description = "Enable scheduled training jobs"
  type        = bool
  default     = false
}

variable "training_schedule" {
  description = "Cron expression for scheduled training"
  type        = string
  default     = "cron(0 0 ? * SUN *)" # Weekly on Sunday
}

variable "default_training_data_uri" {
  description = "Default S3 URI for training data (used in scheduled training)"
  type        = string
  default     = null
}
