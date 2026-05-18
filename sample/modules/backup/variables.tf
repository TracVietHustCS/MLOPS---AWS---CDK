variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Encryption
variable "kms_key_arn" {
  description = "KMS key ARN for encrypting backups"
  type        = string
  default     = null
}

# Daily backup
variable "daily_backup_schedule" {
  description = "Cron expression for daily backup (UTC)"
  type        = string
  default     = "cron(0 5 ? * * *)" # 5 AM UTC daily
}

variable "daily_backup_retention_days" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 35
}

# Weekly backup
variable "enable_weekly_backup" {
  description = "Enable weekly backup rule"
  type        = bool
  default     = true
}

variable "weekly_backup_schedule" {
  description = "Cron expression for weekly backup (UTC)"
  type        = string
  default     = "cron(0 5 ? * SUN *)" # 5 AM UTC every Sunday
}

variable "weekly_backup_retention_days" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 90
}

# Monthly backup
variable "enable_monthly_backup" {
  description = "Enable monthly backup rule"
  type        = bool
  default     = true
}

variable "monthly_backup_schedule" {
  description = "Cron expression for monthly backup (UTC)"
  type        = string
  default     = "cron(0 5 1 * ? *)" # 5 AM UTC on 1st of each month
}

variable "monthly_backup_retention_days" {
  description = "Number of days to retain monthly backups"
  type        = number
  default     = 365
}

variable "monthly_backup_cold_storage_days" {
  description = "Number of days before moving monthly backups to cold storage"
  type        = number
  default     = 90
}

# Cross-region copy
variable "copy_to_vault_arn" {
  description = "ARN of backup vault in another region for cross-region copy"
  type        = string
  default     = null
}

# Resource selection
variable "backup_selection_tags" {
  description = "Tags to select resources for backup"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "backup_resource_arns" {
  description = "List of resource ARNs to backup"
  type        = list(string)
  default     = []
}

# IAM
variable "backup_role_arn" {
  description = "IAM role ARN for AWS Backup. If null, a default role is created"
  type        = string
  default     = null
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
