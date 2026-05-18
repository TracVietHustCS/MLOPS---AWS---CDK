variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "db_name" {
  description = "Name identifier for the Aurora cluster"
  type        = string
}

# Engine configuration
variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

# Serverless v2 configuration
variable "serverless_v2" {
  description = "Use Aurora Serverless v2"
  type        = bool
  default     = true
}

variable "serverless_min_capacity" {
  description = "Minimum ACU for Serverless v2 (0.5 to 128)"
  type        = number
  default     = 0.5
}

variable "serverless_max_capacity" {
  description = "Maximum ACU for Serverless v2 (0.5 to 128)"
  type        = number
  default     = 4
}

# Provisioned instance configuration
variable "instance_class" {
  description = "Instance class for provisioned instances (ignored if serverless_v2=true)"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of cluster instances"
  type        = number
  default     = 1
}

# Database configuration
variable "database_name" {
  description = "Name of the default database to create"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  default     = null
  sensitive   = true
}

variable "master_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master password"
  type        = string
  default     = null
}

variable "use_secrets_manager" {
  description = "Whether to use Secrets Manager for master password"
  type        = bool
  default     = false
}

variable "port" {
  description = "Port for the Aurora cluster"
  type        = number
  default     = 5432
}


# Network configuration
variable "vpc_id" {
  description = "VPC ID where Aurora will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

# Backup configuration
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

# Maintenance configuration
variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

# Encryption configuration
variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for storage encryption"
  type        = string
  default     = null
}

# Security configuration
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make instances publicly accessible"
  type        = bool
  default     = false
}

# Monitoring configuration
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights encryption"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Performance Insights data retention period (days)"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "ARN of the IAM role for enhanced monitoring"
  type        = string
  default     = null
}

# Cluster parameters
variable "cluster_parameters" {
  description = "List of cluster parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
