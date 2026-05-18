variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting CloudTrail logs"
  type        = string
  default     = null
}

variable "include_global_service_events" {
  description = "Include global service events in the trail"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in all regions"
  type        = bool
  default     = false
}

variable "enable_log_file_validation" {
  description = "Enable log file integrity validation"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Send CloudTrail logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "log_archive_days" {
  description = "Days before transitioning logs to Glacier"
  type        = number
  default     = 90
}

variable "log_expiration_days" {
  description = "Days before deleting logs"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = null
}
