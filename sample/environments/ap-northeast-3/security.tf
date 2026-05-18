
# =============================================================================
# Security & Compliance Infrastructure
# =============================================================================
# Landing Zone compliance modules: KMS (5 CMKs), CloudTrail, VPC Flow Logs
# =============================================================================

# -----------------------------------------------------------------------------
# KMS Key 1: S3 Encryption
# -----------------------------------------------------------------------------
module "kms_key_s3" {
  count  = var.deploy_kms ? 1 : 0
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  environment = var.environment
  key_name    = "s3"
  description = "KMS key for S3 bucket encryption"

  enable_key_rotation = true
  key_users           = [module.sagemaker_role.role_arn]
  allowed_services = [
    "s3.amazonaws.com"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# KMS Key 2: RDS Encryption
# -----------------------------------------------------------------------------
module "kms_key_rds" {
  count  = var.deploy_kms ? 1 : 0
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  environment = var.environment
  key_name    = "rds"
  description = "KMS key for RDS PostgreSQL storage encryption"

  enable_key_rotation = true
  key_users           = []
  allowed_services = [
    "rds.amazonaws.com",
    "secretsmanager.amazonaws.com"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# KMS Key 3: SageMaker Encryption
# -----------------------------------------------------------------------------
module "kms_key_sagemaker" {
  count  = var.deploy_kms ? 1 : 0
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  environment = var.environment
  key_name    = "sagemaker"
  description = "KMS key for SageMaker (training volumes, endpoints)"

  enable_key_rotation = true
  key_users           = [module.sagemaker_role.role_arn]
  allowed_services = [
    "sagemaker.amazonaws.com"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# KMS Key 4: CloudTrail & Logs Encryption
# -----------------------------------------------------------------------------
module "kms_key_logs" {
  count  = var.deploy_kms ? 1 : 0
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  environment = var.environment
  key_name    = "logs"
  description = "KMS key for CloudTrail, CloudWatch Logs, VPC Flow Logs"

  enable_key_rotation = true
  key_users           = []
  allowed_services = [
    "logs.amazonaws.com",
    "cloudtrail.amazonaws.com"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# KMS Key 5: ECR & CodeBuild Encryption
# -----------------------------------------------------------------------------
module "kms_key_ecr" {
  count  = var.deploy_kms ? 1 : 0
  source = "../../modules/kms"

  name_prefix = var.name_prefix
  environment = var.environment
  key_name    = "ecr"
  description = "KMS key for ECR images and CodeBuild artifacts"

  enable_key_rotation = true
  key_users           = []
  allowed_services = [
    "ecr.amazonaws.com",
    "codebuild.amazonaws.com"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudTrail
# -----------------------------------------------------------------------------
module "cloudtrail" {
  count  = var.deploy_cloudtrail ? 1 : 0
  source = "../../modules/cloudtrail"

  name_prefix                   = var.name_prefix
  environment                   = var.environment
  kms_key_arn                   = var.deploy_kms ? module.kms_key_logs[0].key_arn : null
  enable_cloudwatch_logs        = true
  cloudwatch_log_retention_days = var.cloudtrail_log_retention_days
  log_archive_days              = var.cloudtrail_log_archive_days
  log_expiration_days           = var.cloudtrail_log_expiration_days
  permissions_boundary          = local.permissions_boundary

  tags = var.tags
}

# -----------------------------------------------------------------------------
# VPC Flow Logs
# -----------------------------------------------------------------------------
module "vpc_flow_logs" {
  count  = var.deploy_vpc_flow_logs ? 1 : 0
  source = "../../modules/vpc-flow-logs"

  name_prefix                   = var.name_prefix
  environment                   = var.environment
  vpc_id                        = local.vpc_id
  traffic_type                  = "ALL"
  log_destination_type          = "cloud-watch-logs"
  cloudwatch_log_retention_days = var.vpc_flow_logs_retention_days
  kms_key_arn                   = var.deploy_kms ? module.kms_key_logs[0].key_arn : null
  permissions_boundary          = local.permissions_boundary

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AWS Backup (RDS, S3)
# -----------------------------------------------------------------------------
module "backup" {
  count  = var.deploy_backup ? 1 : 0
  source = "../../modules/backup"

  name_prefix          = var.name_prefix
  environment          = var.environment
  kms_key_arn          = var.deploy_kms ? module.kms_key_s3[0].key_arn : null
  permissions_boundary = local.permissions_boundary

  # Backup schedules
  daily_backup_schedule       = var.backup_daily_schedule
  daily_backup_retention_days = var.backup_daily_retention_days

  enable_weekly_backup         = var.backup_enable_weekly
  weekly_backup_retention_days = var.backup_weekly_retention_days

  enable_monthly_backup         = var.backup_enable_monthly
  monthly_backup_retention_days = var.backup_monthly_retention_days

  # Resources to backup (RDS + S3)
  backup_resource_arns = concat(
    var.deploy_mlops_rds ? [module.mlops_rds_postgres[0].db_instance_arn] : [],
    [
      module.s3_model_storage.bucket_arn,
      module.s3_rrth_mh_bds.bucket_arn
    ]
  )

  tags = var.tags
}


# =============================================================================
# AWS Config (Compliance Monitoring)
# =============================================================================
module "aws_config" {
  source = "../../modules/aws-config"
  count  = var.deploy_aws_config ? 1 : 0

  name_prefix = var.name_prefix
  environment = var.environment

  # S3 Bucket
  create_s3_bucket      = true
  kms_key_arn           = var.deploy_kms ? module.kms_key_logs[0].key_arn : null
  s3_log_retention_days = var.config_log_retention_days
  s3_log_archive_days   = 90

  # Delivery
  delivery_frequency = var.config_delivery_frequency

  # Recording
  recording_all_resources  = true
  include_global_resources = true

  # Managed Rules
  enable_managed_rules = var.config_enable_managed_rules

  # IAM
  permissions_boundary = local.permissions_boundary

  tags = var.tags
}
