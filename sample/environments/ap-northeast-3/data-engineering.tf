# =============================================================================
# Data Engineering Infrastructure
# =============================================================================
# AWS Glue (ETL)
# Note: API Gateway moved to api.tf with Lambda integration
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Glue - ETL Jobs
# -----------------------------------------------------------------------------
module "glue" {
  count  = var.deploy_glue ? 1 : 0
  source = "../../modules/glue"

  name_prefix          = var.name_prefix
  environment          = var.environment
  database_name        = var.glue_database_name
  database_description = "MLOps data catalog for ETL jobs"
  permissions_boundary = local.permissions_boundary

  # Crawler
  create_crawler     = var.glue_create_crawler
  crawler_name       = var.glue_crawler_name
  crawler_schedule   = var.glue_crawler_schedule
  crawler_s3_targets = var.glue_crawler_s3_targets

  # ETL Job
  create_etl_job        = var.glue_create_etl_job
  job_name              = var.glue_job_name
  job_script_location   = var.glue_job_script_location
  glue_version          = var.glue_version
  job_worker_type       = var.glue_job_worker_type
  job_number_of_workers = var.glue_job_number_of_workers
  job_timeout           = var.glue_job_timeout
  job_logs_bucket       = module.s3_model_storage.bucket_name

  # Delta Lake support (read/write Delta tables)
  enable_delta_lake = var.glue_enable_delta_lake

  # Connection (for RDS/on-premise DB)
  create_connection             = var.glue_create_connection
  connection_name               = var.glue_connection_name
  connection_type               = var.glue_connection_type
  connection_properties         = var.glue_connection_properties
  connection_subnet_id          = length(local.subnet_ids) > 0 ? local.subnet_ids[0] : null
  connection_security_group_ids = [module.glue_sg.security_group_id]

  s3_access_arns = [
    module.s3_model_storage.bucket_arn,
    "${module.s3_model_storage.bucket_arn}/*"
  ]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# WAF for API Gateway
# -----------------------------------------------------------------------------
module "waf" {
  count  = var.deploy_waf ? 1 : 0
  source = "../../modules/waf"

  name_prefix = var.name_prefix
  environment = var.environment

  # Associate with API Gateway stage (if API Gateway is deployed)
  enable_api_gateway_association = var.deploy_api_gateway
  api_gateway_stage_arn          = var.deploy_api_gateway ? module.api_gateway[0].stage_arn : null

  # Protection rules
  enable_sql_injection_protection = var.waf_enable_sql_injection_protection
  enable_rate_limiting            = var.waf_enable_rate_limiting
  rate_limit                      = var.waf_rate_limit

  # Logging
  enable_logging     = var.waf_enable_logging
  log_retention_days = var.waf_log_retention_days

  tags = var.tags
}
