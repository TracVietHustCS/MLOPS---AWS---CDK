# Aurora PostgreSQL Module
# Creates Aurora PostgreSQL cluster with Serverless v2 or Provisioned instances

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Retrieve master password from Secrets Manager
data "aws_secretsmanager_secret_version" "master_password" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = var.master_password_secret_arn
}

locals {
  master_password = var.use_secrets_manager ? data.aws_secretsmanager_secret_version.master_password[0].secret_string : var.master_password
  cluster_id      = lower("${var.name_prefix}-${var.environment}-${var.db_name}")
}

# DB Subnet Group
resource "aws_db_subnet_group" "aurora" {
  name        = "${local.cluster_id}-subnet-group"
  description = "Subnet group for Aurora PostgreSQL ${local.cluster_id}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    {
      Name        = "${local.cluster_id}-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# Aurora Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${local.cluster_id}-cluster-params"
  family      = "aurora-postgresql${split(".", var.engine_version)[0]}"
  description = "Cluster parameter group for ${local.cluster_id}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = var.tags
}


# Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = local.cluster_id

  engine         = "aurora-postgresql"
  engine_mode    = var.serverless_v2 ? "provisioned" : "provisioned"
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.master_username
  master_password = local.master_password
  port            = var.port

  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = var.security_group_ids
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # Serverless v2 scaling configuration
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverless_v2 ? [1] : []
    content {
      min_capacity = var.serverless_min_capacity
      max_capacity = var.serverless_max_capacity
    }
  }

  # Backup settings
  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = var.preferred_backup_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.cluster_id}-final-snapshot"

  # Maintenance
  preferred_maintenance_window = var.preferred_maintenance_window
  apply_immediately            = var.apply_immediately

  # Protection
  deletion_protection = var.deletion_protection

  # IAM authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # CloudWatch logs
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(
    {
      Name        = local.cluster_id
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [master_password]
  }
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "aurora" {
  count = var.instance_count

  identifier         = "${local.cluster_id}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  instance_class = var.serverless_v2 ? "db.serverless" : var.instance_class

  db_subnet_group_name = aws_db_subnet_group.aurora.name
  publicly_accessible  = var.publicly_accessible

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = merge(
    {
      Name        = "${local.cluster_id}-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )
}
