# =============================================================================
# MLOps Infrastructure Configuration
# =============================================================================
# This file contains all MLOps-related modules:
# - Secrets Manager (for RDS password)
# - RDS PostgreSQL (for MLflow/metadata storage)
# - SageMaker Feature Store
# - SageMaker Model Registry
# - SageMaker Pipeline
# - SageMaker Model Monitoring
# =============================================================================

# -----------------------------------------------------------------------------
# RDS PostgreSQL Security Group
# -----------------------------------------------------------------------------
module "rds_sg" {
  count  = var.deploy_mlops_rds ? 1 : 0
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "rds"
  description   = "Security group for RDS PostgreSQL"

  ingress_rules = {
    postgres = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "PostgreSQL from VPC"
    }
  }

  egress_rules = {}

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Secrets Manager - RDS Password
# -----------------------------------------------------------------------------
module "mlops_secrets_manager" {
  count  = var.deploy_mlops_rds ? 1 : 0
  source = "../../modules/secrets-manager"

  name_prefix             = var.name_prefix
  environment             = var.environment
  recovery_window_in_days = 0 # Force immediate deletion on destroy

  secrets = {
    "rds-password" = {
      name                     = "rds-master-password"
      description              = "Master password for MLOps RDS PostgreSQL"
      generate_random_password = true
      password_length          = 32
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL - MLOps Metadata Store
# -----------------------------------------------------------------------------
module "mlops_rds_postgres" {
  count  = var.deploy_mlops_rds ? 1 : 0
  source = "../../modules/rds-postgres"

  name_prefix = var.name_prefix
  environment = var.environment
  db_name     = var.mlops_rds_name

  engine_version = var.mlops_rds_engine_version
  instance_class = var.mlops_rds_instance_class

  allocated_storage = 100
  storage_type      = "gp2"
  multi_az          = true

  database_name              = var.mlops_rds_database_name
  master_username            = var.mlops_rds_master_username
  use_secrets_manager        = true
  master_password_secret_arn = module.mlops_secrets_manager[0].secret_arns["rds-password"]

  vpc_id             = local.vpc_id
  subnet_ids         = local.subnet_ids
  security_group_ids = [module.rds_sg[0].security_group_id]

  backup_retention_period = var.mlops_rds_backup_retention_period
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"

  tags = var.tags

  depends_on = [module.mlops_secrets_manager]
}

# -----------------------------------------------------------------------------
# SageMaker Feature Store
# -----------------------------------------------------------------------------
module "mlops_feature_store" {
  count  = var.deploy_mlops_feature_store ? 1 : 0
  source = "../../modules/sagemaker-feature-store"

  name_prefix        = var.name_prefix
  environment        = var.environment
  feature_group_name = var.mlops_feature_group_name
  role_arn           = module.sagemaker_role.role_arn

  record_identifier_name = var.mlops_feature_record_identifier
  event_time_name        = var.mlops_feature_event_time_name
  feature_definitions    = var.mlops_feature_definitions

  enable_online_store  = var.mlops_feature_enable_online_store
  enable_offline_store = var.mlops_feature_enable_offline_store
  offline_store_s3_uri = var.mlops_feature_enable_offline_store ? "s3://${module.s3_model_storage.bucket_name}/feature-store/" : null

  tags = var.tags

  depends_on = [time_sleep.wait_for_iam_propagation]
}

# -----------------------------------------------------------------------------
# SageMaker Model Registry
# -----------------------------------------------------------------------------
module "mlops_model_registry" {
  count  = var.deploy_mlops_model_registry ? 1 : 0
  source = "../../modules/sagemaker-model-registry"

  name_prefix              = var.name_prefix
  environment              = var.environment
  model_package_group_name = var.mlops_model_package_group_name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# SageMaker Pipeline
# -----------------------------------------------------------------------------
module "mlops_pipeline" {
  count  = var.deploy_mlops_pipeline ? 1 : 0
  source = "../../modules/sagemaker-pipeline"

  name_prefix   = var.name_prefix
  environment   = var.environment
  pipeline_name = var.mlops_pipeline_name
  role_arn      = module.sagemaker_role.role_arn

  pipeline_definition_s3_bucket = module.s3_model_storage.bucket_name
  pipeline_definition_s3_key    = var.mlops_pipeline_definition_s3_key

  subnet_ids         = local.subnet_ids
  security_group_ids = [module.sagemaker_sg.security_group_id]

  tags = var.tags

  depends_on = [time_sleep.wait_for_iam_propagation]
}

# -----------------------------------------------------------------------------
# SageMaker Model Monitoring
# -----------------------------------------------------------------------------
module "mlops_model_monitoring" {
  count  = var.deploy_mlops_model_monitoring && (var.deploy_text_model || var.deploy_vision_model) ? 1 : 0
  source = "../../modules/sagemaker-model-monitoring"

  name_prefix   = var.name_prefix
  environment   = var.environment
  endpoint_name = var.deploy_text_model ? module.sagemaker_endpoint_text[0].endpoint_name : module.sagemaker_endpoint_vision[0].endpoint_name
  role_arn      = module.sagemaker_role.role_arn

  schedule_expression = var.mlops_monitoring_schedule_expression
  output_s3_uri       = "s3://${module.s3_model_storage.bucket_name}/monitoring/"

  instance_type  = var.mlops_monitoring_instance_type
  instance_count = var.mlops_monitoring_instance_count

  subnet_ids         = local.subnet_ids
  security_group_ids = [module.sagemaker_sg.security_group_id]

  tags = var.tags

  depends_on = [
    time_sleep.wait_for_iam_propagation,
    module.sagemaker_endpoint_text,
    module.sagemaker_endpoint_vision
  ]
}


# =============================================================================
# SageMaker Training Workflow
# =============================================================================
module "sagemaker_training" {
  source = "../../modules/sagemaker-training"
  count  = var.deploy_sagemaker_training && var.training_image != null ? 1 : 0

  name_prefix = var.name_prefix
  environment = var.environment

  # IAM
  sagemaker_role_arn   = module.sagemaker_role.role_arn
  permissions_boundary = local.permissions_boundary

  # Training Configuration
  training_image         = var.training_image
  training_instance_type = var.training_instance_type
  training_instance_count = var.training_instance_count
  training_volume_size   = var.training_volume_size

  # Output
  output_bucket = module.s3_model_storage.bucket_name
  output_prefix = "model-artifacts"

  # Security
  kms_key_arn = var.deploy_kms ? module.kms_key_sagemaker[0].key_arn : null
  vpc_config = {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [module.sagemaker_sg.security_group_id]
  }

  # Scheduled Training
  enable_scheduled_training = var.enable_scheduled_training
  training_schedule         = var.training_schedule
  default_training_data_uri = "s3://${module.s3_model_storage.bucket_name}/training-data/"

  tags = var.tags
}
