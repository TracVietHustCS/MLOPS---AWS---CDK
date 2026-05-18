# =============================================================================
# AWS Config Variables
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
# Config Recorder
# -----------------------------------------------------------------------------
variable "recording_all_resources" {
  description = "Record all supported resource types"
  type        = bool
  default     = true
}

variable "recording_resource_types" {
  description = "List of specific resource types to record (if not recording all)"
  type        = list(string)
  default     = []
}

variable "include_global_resources" {
  description = "Include global resources (IAM, etc.) in recording"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Delivery Channel
# -----------------------------------------------------------------------------
variable "s3_bucket_name" {
  description = "S3 bucket name for Config delivery (if null, creates new bucket)"
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = "S3 key prefix for Config logs"
  type        = string
  default     = "config"
}

variable "delivery_frequency" {
  description = "Frequency for Config snapshots (One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours)"
  type        = string
  default     = "TwentyFour_Hours"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for Config notifications (optional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# S3 Bucket Configuration
# -----------------------------------------------------------------------------
variable "create_s3_bucket" {
  description = "Create S3 bucket for Config logs"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 encryption"
  type        = string
  default     = null
}

variable "s3_log_retention_days" {
  description = "Days to retain Config logs in S3"
  type        = number
  default     = 365
}

variable "s3_log_archive_days" {
  description = "Days before archiving to Glacier"
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Force destroy S3 bucket even if not empty"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------
variable "permissions_boundary" {
  description = "IAM permissions boundary ARN"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Config Rules
# -----------------------------------------------------------------------------
variable "enable_managed_rules" {
  description = "Enable AWS managed Config rules"
  type        = bool
  default     = true
}

variable "managed_rules" {
  description = "List of AWS managed Config rules to enable"
  type = list(object({
    name                        = string
    identifier                  = string
    input_parameters            = optional(map(string), {})
    maximum_execution_frequency = optional(string, null)
  }))
  default = [
    {
      name       = "s3-bucket-versioning-enabled"
      identifier = "S3_BUCKET_VERSIONING_ENABLED"
    },
    {
      name       = "s3-bucket-server-side-encryption-enabled"
      identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
    },
    {
      name       = "encrypted-volumes"
      identifier = "ENCRYPTED_VOLUMES"
    },
    {
      name       = "rds-storage-encrypted"
      identifier = "RDS_STORAGE_ENCRYPTED"
    },
    {
      name       = "vpc-flow-logs-enabled"
      identifier = "VPC_FLOW_LOGS_ENABLED"
    },
    {
      name       = "cloudtrail-enabled"
      identifier = "CLOUD_TRAIL_ENABLED"
    }
  ]
}
