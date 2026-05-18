# RDS PostgreSQL Module
# Creates RDS PostgreSQL instance with Multi-AZ support

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Retrieve master password from Secrets Manager
data "aws_secretsmanager_secret_version" "master_password" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = var.master_password_secret_arn
}

locals {
  master_password   = var.use_secrets_manager ? data.aws_secretsmanager_secret_version.master_password[0].secret_string : var.master_password
  db_identifier     = lower("${var.name_prefix}-${var.environment}-${var.db_name}")
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds" {
  name        = "${local.db_identifier}-subnet-group"
  description = "Subnet group for RDS PostgreSQL ${local.db_identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    {
      Name        = "${local.db_identifier}-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "rds" {
  identifier = local.db_identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_name  = var.database_name
  username = var.master_username
  password = local.master_password
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = var.security_group_ids

  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible
  deletion_protection    = var.deletion_protection

  # Backup settings
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.preferred_backup_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.db_identifier}-final-snapshot"

  # Maintenance
  maintenance_window         = var.preferred_maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # IAM authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # CloudWatch logs
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(
    {
      Name        = local.db_identifier
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [password]
  }
}
