# =============================================================================
# ACB SageMaker - ap-northeast-3 (Osaka) - Dev
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
aws_region  = "<AWS_REGION>"
aws_profile = "<AWS_PROFILE>"
name_prefix = "<NAME_PREFIX>"
environment = "<ENVIRONMENT>"

# LMI Container Configuration
lmi_container_account_id = "<LMI_CONTAINER_ACCOUNT_ID>"
lmi_container_version    = "<LMI_CONTAINER_VERSION>"

# CloudWatch Metrics
cloudwatch_metrics_namespace = "<CLOUDWATCH_METRICS_NAMESPACE>"

# Additional Tags
tags = {}

# -----------------------------------------------------------------------------
# Model Deployment Flags
# -----------------------------------------------------------------------------
deploy_vision_model = false
deploy_text_model   = false

# -----------------------------------------------------------------------------
# Vision Model Configuration
# -----------------------------------------------------------------------------
vision_model_name    = "<VISION_MODEL_NAME>"
vision_model_id      = "<VISION_MODEL_ID>"
vision_instance_type = "<VISION_INSTANCE_TYPE>"
vision_model_s3_key  = "<VISION_MODEL_S3_KEY>"
is_moe_vision_model  = false

# -----------------------------------------------------------------------------
# Text Model Configuration
# -----------------------------------------------------------------------------
text_model_name    = "<TEXT_MODEL_NAME>"
text_model_id      = "<TEXT_MODEL_ID>"
text_instance_type = "<TEXT_INSTANCE_TYPE>"
text_model_s3_key  = "<TEXT_MODEL_S3_KEY>"
is_moe_text_model  = false

# -----------------------------------------------------------------------------
# Instance & Autoscaling
# -----------------------------------------------------------------------------
initial_instance_count     = 1
enable_autoscaling_vision  = false
vision_min_instance_count  = 1
vision_max_instance_count  = 1
enable_autoscaling_text    = false
text_min_instance_count    = 1
text_max_instance_count    = 1
target_concurrent_requests = 5

# -----------------------------------------------------------------------------
# Model Performance
# -----------------------------------------------------------------------------
tensor_parallel_degree = "<TENSOR_PARALLEL_DEGREE>"
max_model_len          = 4096
max_batched_len        = 4096

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
create_vpc            = true
vpc_cidr_block        = "<VPC_CIDR_BLOCK>"
public_subnet_1_cidr  = "<PUBLIC_SUBNET_1_CIDR>"
public_subnet_2_cidr  = "<PUBLIC_SUBNET_2_CIDR>"
private_subnet_1_cidr = "<PRIVATE_SUBNET_1_CIDR>"
private_subnet_2_cidr = "<PRIVATE_SUBNET_2_CIDR>"
create_nat_gateway    = true

vpc_id     = null
subnet_ids = []

# Security Group Egress Control
restrict_egress_to_vpc = false
egress_cidr_blocks     = []

create_vpc_endpoints = true

# -----------------------------------------------------------------------------
# VPC Endpoints
# -----------------------------------------------------------------------------
create_s3_gateway               = true
create_s3_interface             = false
create_sagemaker_endpoint       = true
create_ecr_endpoint             = false
create_ecr_docker_endpoint      = false
create_cloudwatch_endpoint      = true
create_secrets_manager_endpoint = true
create_api_gateway_endpoint     = true
create_lambda_endpoint          = true
create_ssm_endpoint             = false

# -----------------------------------------------------------------------------
# ALB Configuration
# -----------------------------------------------------------------------------
create_alb              = false
alb_internal            = true
alb_subnet_ids          = []
alb_certificate_arn     = null
alb_ingress_cidr_blocks = ["<ALB_INGRESS_CIDR>"]

# -----------------------------------------------------------------------------
# ECR & Endpoint
# -----------------------------------------------------------------------------
create_ecr_repository       = true
create_endpoint             = false
custom_container_image      = ""
lambda_function_source_path = "<LAMBDA_FUNCTION_SOURCE_PATH>"

# -----------------------------------------------------------------------------
# Scheduler
# -----------------------------------------------------------------------------
enable_endpoint_scheduler       = false
schedule_on_off_text_endpoint   = false
schedule_on_off_vision_endpoint = false
scheduler_stop_cron             = "<SCHEDULER_STOP_CRON>"
scheduler_start_cron            = "<SCHEDULER_START_CRON>"
scheduler_instance_count        = 1

# -----------------------------------------------------------------------------
# Data Bucket
# -----------------------------------------------------------------------------
data_bucket_name = "<DATA_BUCKET_NAME>"

# -----------------------------------------------------------------------------
# Permissions Boundary
# -----------------------------------------------------------------------------
enable_permissions_boundary      = false
permissions_boundary_policy_name = "<PERMISSIONS_BOUNDARY_POLICY_NAME>"

# -----------------------------------------------------------------------------
# Security & Compliance (Landing Zone)
# -----------------------------------------------------------------------------
deploy_kms                     = true
deploy_cloudtrail              = true
deploy_vpc_flow_logs           = true
cloudtrail_log_retention_days  = 90
cloudtrail_log_archive_days    = 90
cloudtrail_log_expiration_days = 365
vpc_flow_logs_retention_days   = 90

# -----------------------------------------------------------------------------
# AWS Backup
# -----------------------------------------------------------------------------
deploy_backup                 = true
backup_daily_schedule         = "<BACKUP_DAILY_SCHEDULE>"
backup_daily_retention_days   = 35
backup_enable_weekly          = true
backup_weekly_retention_days  = 90
backup_enable_monthly         = true
backup_monthly_retention_days = 365

# -----------------------------------------------------------------------------
# SageMaker CodeBuild
# -----------------------------------------------------------------------------
deploy_sagemaker_codebuild       = true
sagemaker_codebuild_compute_type = "<CODEBUILD_COMPUTE_TYPE>"
sagemaker_codebuild_image        = "<CODEBUILD_IMAGE>"

# -----------------------------------------------------------------------------
# MLOps Modules
# -----------------------------------------------------------------------------
deploy_mlops_rds              = true
deploy_mlops_feature_store    = true
deploy_mlops_model_registry   = true
deploy_mlops_pipeline         = false
deploy_mlops_model_monitoring = true

# RDS PostgreSQL Configuration
mlops_rds_name                    = "<MLOPS_RDS_NAME>"
mlops_rds_engine_version          = "<MLOPS_RDS_ENGINE_VERSION>"
mlops_rds_instance_class          = "<MLOPS_RDS_INSTANCE_CLASS>"
mlops_rds_database_name           = "<MLOPS_RDS_DATABASE_NAME>"
mlops_rds_master_username         = "<MLOPS_RDS_MASTER_USERNAME>"
mlops_rds_backup_retention_period = 7

# SageMaker Feature Store Configuration
mlops_feature_group_name           = "<MLOPS_FEATURE_GROUP_NAME>"
mlops_feature_record_identifier    = "<MLOPS_FEATURE_RECORD_IDENTIFIER>"
mlops_feature_event_time_name      = "<MLOPS_FEATURE_EVENT_TIME_NAME>"
mlops_feature_enable_online_store  = true
mlops_feature_enable_offline_store = true
mlops_feature_definitions = [
  { feature_name = "<FEATURE_NAME_1>", feature_type = "<FEATURE_TYPE_1>" },
  { feature_name = "<FEATURE_NAME_2>", feature_type = "<FEATURE_TYPE_2>" }
]

# SageMaker Model Registry Configuration
mlops_model_package_group_name = "<MLOPS_MODEL_PACKAGE_GROUP_NAME>"

# SageMaker Pipeline Configuration
mlops_pipeline_name              = "<MLOPS_PIPELINE_NAME>"
mlops_pipeline_definition_s3_key = "<MLOPS_PIPELINE_DEFINITION_S3_KEY>"

# Model Monitoring Configuration
mlops_monitoring_schedule_expression = "<MLOPS_MONITORING_SCHEDULE_EXPRESSION>"
mlops_monitoring_instance_type       = "<MLOPS_MONITORING_INSTANCE_TYPE>"
mlops_monitoring_instance_count      = 1

# -----------------------------------------------------------------------------
# AWS Glue
# -----------------------------------------------------------------------------
deploy_glue                = true
glue_database_name         = "<GLUE_DATABASE_NAME>"
glue_create_crawler        = true
glue_create_etl_job        = true
glue_create_connection     = false
glue_job_worker_type       = "<GLUE_JOB_WORKER_TYPE>"
glue_job_number_of_workers = 2
glue_enable_delta_lake     = true

glue_crawler_name       = "<GLUE_CRAWLER_NAME>"
glue_crawler_schedule   = null
glue_crawler_s3_targets = []

glue_job_name            = "<GLUE_JOB_NAME>"
glue_version             = "<GLUE_VERSION>"
glue_job_script_location = null
glue_job_timeout         = 60

glue_connection_name       = "<GLUE_CONNECTION_NAME>"
glue_connection_type       = "<GLUE_CONNECTION_TYPE>"
glue_connection_properties = {}

# -----------------------------------------------------------------------------
# API Gateway
# -----------------------------------------------------------------------------
deploy_api_gateway                 = true
api_gateway_name                   = "<API_GATEWAY_NAME>"
api_gateway_endpoint_type          = "<API_GATEWAY_ENDPOINT_TYPE>"
api_gateway_stage_name             = "<API_GATEWAY_STAGE_NAME>"
api_gateway_throttling_burst_limit = 100
api_gateway_throttling_rate_limit  = 50
api_gateway_log_retention_days     = 30
api_gateway_enable_cors            = true
api_gateway_require_api_key        = false

# -----------------------------------------------------------------------------
# WAF
# -----------------------------------------------------------------------------
deploy_waf                          = true
waf_enable_sql_injection_protection = true
waf_enable_rate_limiting            = true
waf_rate_limit                      = 2000
waf_enable_logging                  = true
waf_log_retention_days              = 30

# -----------------------------------------------------------------------------
# AWS Location Service
# -----------------------------------------------------------------------------
deploy_location_service             = true
location_service_region             = "<LOCATION_SERVICE_REGION>"
location_create_place_index         = true
location_create_map                 = true
location_create_tracker             = false
location_create_geofence_collection = false
location_create_route_calculator    = false
location_data_source                = "<LOCATION_DATA_SOURCE>"

# -----------------------------------------------------------------------------
# Transit Gateway Attachment
# -----------------------------------------------------------------------------
deploy_transit_gateway_attachment = false
transit_gateway_id                = null
tgw_destination_cidr              = "<TGW_DESTINATION_CIDR>"

# -----------------------------------------------------------------------------
# AWS Config
# -----------------------------------------------------------------------------
deploy_aws_config           = false
config_delivery_frequency   = "<CONFIG_DELIVERY_FREQUENCY>"
config_log_retention_days   = 365
config_enable_managed_rules = true

# -----------------------------------------------------------------------------
# SageMaker Training
# -----------------------------------------------------------------------------
deploy_sagemaker_training = true
training_image            = null
training_instance_type    = "<TRAINING_INSTANCE_TYPE>"
training_instance_count   = 1
training_volume_size      = 50
enable_scheduled_training = false
training_schedule         = "<TRAINING_SCHEDULE>"

# -----------------------------------------------------------------------------
# EC2 Test Instance
# -----------------------------------------------------------------------------
deploy_test_instance = false
test_instance_type   = "<TEST_INSTANCE_TYPE>"

# -----------------------------------------------------------------------------
# SageMaker Studio
# -----------------------------------------------------------------------------
deploy_sagemaker_studio      = true
studio_auth_mode             = "<STUDIO_AUTH_MODE>"
studio_default_instance_type = "<STUDIO_DEFAULT_INSTANCE_TYPE>"
studio_user_profiles = [
  {
    name                   = "<STUDIO_USER_NAME>"
    notebook_instance_type = "<STUDIO_NOTEBOOK_INSTANCE_TYPE>"
  }
]
