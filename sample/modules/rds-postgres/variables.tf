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
  description = "Name identifier for the RDS instance"
  type        = string
}

# Engine configuration
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

# Instance configuration
variable "instance_class" {
  description = "Instance class for RDS"
  type        = string
  default     = "db.t3.medium"
}

# Storage configuration
variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Max allocated storage for autoscaling (0 to disable)"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp2"
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
  description = "Port for the RDS instance"
  type        = number
  default     = 5432
}

# Network configuration
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
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

# High availability
variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
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
  description = "Make instance publicly accessible"
  type        = bool
  default     = false
}

# Monitoring configuration
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
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

# Tags
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
