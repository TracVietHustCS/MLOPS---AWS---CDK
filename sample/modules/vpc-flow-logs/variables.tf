variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to enable flow logs on"
  type        = string
}

variable "traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"
}

variable "log_destination_type" {
  description = "Destination type for flow logs (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
}

variable "max_aggregation_interval" {
  description = "Maximum interval of time during which a flow of packets is captured (60 or 600 seconds)"
  type        = number
  default     = 600
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs"
  type        = string
  default     = null
}

variable "log_archive_days" {
  description = "Days before transitioning S3 logs to Glacier"
  type        = number
  default     = 90
}

variable "log_expiration_days" {
  description = "Days before deleting S3 logs"
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
