variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "acb-dev"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "lmi_container_account_id" {
  description = "AWS account ID for LMI container registry"
  type        = string
  default     = "763104351884"
}

variable "lmi_container_version" {
  description = "LMI container version tag"
  type        = string
  default     = "0.33.0-lmi15.0.0-cu128"
}

variable "deploy_vision_model" {
  description = "Whether to deploy Qwen 2.5 VL 7B vision-language model"
  type        = bool
  default     = true
}

variable "vision_model_id" {
  description = "Hugging Face model ID for vision model"
  type        = string
  default     = "Qwen/Qwen2.5-VL-7B-Instruct"
}

variable "vision_model_s3_key" {
  description = "S3 key (path) where vision model artifacts are stored"
  type        = string
  default     = "qwen2.5-vl-7b/model.tar.gz"
}

variable "deploy_text_model" {
  description = "Whether to deploy Qwen 3 8B FP8 text-only model"
  type        = bool
  default     = false
}

variable "text_model_id" {
  description = "Hugging Face model ID for text model"
  type        = string
  default     = "Qwen/Qwen3-14B-FP8"
}

variable "text_model_s3_key" {
  description = "S3 key (path) where text model artifacts are stored"
  type        = string
  default     = "qwen3-14b-fp8/model.tar.gz"
}



variable "initial_instance_count" {
  description = "Initial number of instances for the endpoint"
  type        = number
  default     = 1

  validation {
    condition     = var.initial_instance_count > 0
    error_message = "Initial instance count must be at least 1."
  }
}

variable "tensor_parallel_degree" {
  description = "Number of GPUs to use for tensor parallelism"
  type        = string
  default     = "1"
}

variable "max_model_len" {
  description = "Maximum sequence length for the model"
  type        = string
  default     = "8192"
}

variable "vpc_id" {
  description = "VPC ID for private endpoint deployment. Leave null for public endpoint"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of private subnet IDs for SageMaker endpoint. Required if vpc_id is provided"
  type        = list(string)
  default     = []
}

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints for S3, ECR, and CloudWatch Logs"
  type        = bool
  default     = true
}

variable "create_alb" {
  description = "Whether to create an Application Load Balancer in front of SageMaker endpoint"
  type        = bool
  default     = false
}

variable "alb_internal" {
  description = "Whether the ALB should be internal (true) or internet-facing (false)"
  type        = bool
  default     = true
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for ALB (must be in at least 2 AZs)"
  type        = list(string)
  default     = []
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "alb_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listener"
  type        = string
  default     = null
}


variable "lambda_function_source_path" {
  description = "Path to Lambda function source file (relative to root)"
  type        = string
  default     = "lambda/sagemaker_proxy.py"
}

variable "create_ecr_repository" {
  description = "Whether to create ECR repository for custom vLLM container"
  type        = bool
  default     = false
}

variable "custom_container_image" {
  description = "Custom Docker container image URI for SageMaker (leave empty to use default LMI container)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "text_instance_type" {
  description = "Instance type for text model"
  type        = string
  default     = "ml.g5.2xlarge"
}

variable "vision_instance_type" {
  description = "Instance type for vision model"
  type        = string
  default     = "ml.g5.2xlarge"
}

variable "enable_endpoint_scheduler" {
  description = "Enable automatic start/stop scheduling for Evenbridge SageMaker endpoints"
  type        = bool
  default     = false
}

variable "schedule_on_off_vision_endpoint" {
  description = "Enable automatic start/stop scheduling for SageMaker Vision endpoints"
  type        = bool
  default     = false
}

variable "schedule_on_off_text_endpoint" {
  description = "Enable automatic start/stop scheduling for SageMaker Text endpoints"
  type        = bool
  default     = false
}

variable "scheduler_stop_cron" {
  description = "Cron expression for stopping endpoints (UTC time)"
  type        = string
  default     = "cron(0 9 ? * MON-FRI *)"
}

variable "scheduler_start_cron" {
  description = "Cron expression for starting endpoints (UTC time)"
  type        = string
  default     = "cron(0 23 ? * SUN-THU *)"
}

variable "scheduler_instance_count" {
  description = "Number of instances to start endpoints with"
  type        = number
  default     = 1
}

variable "create_endpoint" {
  description = "Create Sagemaker endpoint or not"
  type        = bool
  default     = false
}

variable "text_model_name" {
  description = "Sagemaker text model name"
  type        = string
}

variable "vision_model_name" {
  description = "Sagemaker vision model name"
  type        = string
}

variable "max_batched_len" {
  description = "Batch size tokens"
  type        = number
  default     = 32768
}

variable "is_moe_text_model" {
  description = "Check the config.json file to see it contains 'num_experts' or 'moe_layer_freq'"
  type        = bool
  default     = false
}

variable "is_moe_vision_model" {
  description = "Check the config.json file to see it contains 'num_experts' or 'moe_layer_freq'"
  type        = bool
  default     = false
}

variable "cloudwatch_metrics_namespace" {
  description = "CloudWatch custom metrics namespace"
  type        = string
  default     = "ACB/SageMaker"
}

variable "create_s3_gateway" {
  description = "Gateway S3 for private subnet (free, DNS resolves to public IP)"
  type        = bool
  default     = false
}

variable "create_s3_interface" {
  description = "Interface S3 endpoint (costs money, DNS resolves to private IP - use for full private)"
  type        = bool
  default     = false
}

variable "create_sagemaker_endpoint" {
  description = "Sagemaker endpoint for private subnet"
  type        = bool
  default     = false
}

variable "create_ecr_endpoint" {
  description = "ECR endpoint for private subnet"
  type        = bool
  default     = false
}

variable "create_ecr_docker_endpoint" {
  description = "ECR endpoint for private subnet"
  type        = bool
  default     = false
}

variable "create_cloudwatch_endpoint" {
  description = "Cloudwatch endpoint for private subnet"
  type        = bool
  default     = false
}

variable "create_secrets_manager_endpoint" {
  description = "Secerts manager endpoint for private subnet"
  type        = bool
  default     = false
}

variable "create_api_gateway_endpoint" {
  description = "Create API Gateway (execute-api) private endpoint"
  type        = bool
  default     = false
}

variable "create_lambda_endpoint" {
  description = "Create Lambda private endpoint"
  type        = bool
  default     = false
}

variable "create_ssm_endpoint" {
  description = "Create SSM endpoints for Session Manager (ssm, ssmmessages, ec2messages)"
  type        = bool
  default     = false
}

variable "enable_autoscaling_vision" {
  description = "Enable autoscaling for vision model endpoint"
  type        = bool
  default     = false
}

variable "enable_autoscaling_text" {
  description = "Enable autoscaling for text model endpoint"
  type        = bool
  default     = false
}

variable "vision_min_instance_count" {
  description = "Minimum instance count for vision model autoscaling"
  type        = number
  default     = 1
}

variable "vision_max_instance_count" {
  description = "Maximum instance count for vision model autoscaling"
  type        = number
  default     = 3
}

variable "text_min_instance_count" {
  description = "Minimum instance count for text model autoscaling"
  type        = number
  default     = 1
}

variable "text_max_instance_count" {
  description = "Maximum instance count for text model autoscaling"
  type        = number
  default     = 3
}

variable "target_concurrent_requests" {
  description = "Target concurrent requests per instance for autoscaling (applies to both models)"
  type        = number
  default     = 10
}


# =============================================================================
# MLOps Variables
# =============================================================================

# -----------------------------------------------------------------------------
# MLOps Module Enable Flags
# -----------------------------------------------------------------------------

variable "deploy_mlops_rds" {
  description = "Whether to deploy RDS PostgreSQL for MLOps metadata storage"
  type        = bool
  default     = false
}

variable "deploy_mlops_feature_store" {
  description = "Whether to deploy SageMaker Feature Store"
  type        = bool
  default     = false
}

variable "deploy_mlops_model_registry" {
  description = "Whether to deploy SageMaker Model Registry"
  type        = bool
  default     = false
}

variable "deploy_mlops_pipeline" {
  description = "Whether to deploy SageMaker Pipeline"
  type        = bool
  default     = false
}

variable "deploy_mlops_model_monitoring" {
  description = "Whether to deploy SageMaker Model Monitoring"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Variables
# -----------------------------------------------------------------------------

variable "mlops_rds_name" {
  description = "Name of the RDS instance for MLOps metadata"
  type        = string
  default     = "mlops-metadata"
}

variable "mlops_rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "mlops_rds_instance_class" {
  description = "Instance class for RDS"
  type        = string
  default     = "db.t4g.medium"
}

variable "mlops_rds_database_name" {
  description = "Name of the default database"
  type        = string
  default     = "mlops"
}

variable "mlops_rds_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "mlopsadmin"
}

variable "mlops_rds_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# SageMaker Feature Store Variables
# -----------------------------------------------------------------------------

variable "mlops_feature_group_name" {
  description = "Name of the SageMaker Feature Group"
  type        = string
  default     = "customer-features"
}

variable "mlops_feature_record_identifier" {
  description = "Name of the record identifier feature"
  type        = string
  default     = "customer_id"
}

variable "mlops_feature_event_time_name" {
  description = "Name of the event time feature"
  type        = string
  default     = "event_time"
}

variable "mlops_feature_definitions" {
  description = "List of feature definitions for the Feature Group"
  type = list(object({
    feature_name = string
    feature_type = string
  }))
  default = [
    { feature_name = "age", feature_type = "Integral" },
    { feature_name = "income", feature_type = "Fractional" }
  ]
}

variable "mlops_feature_enable_online_store" {
  description = "Enable online store for Feature Group"
  type        = bool
  default     = true
}

variable "mlops_feature_enable_offline_store" {
  description = "Enable offline store for Feature Group"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# SageMaker Model Registry Variables
# -----------------------------------------------------------------------------

variable "mlops_model_package_group_name" {
  description = "Name of the SageMaker Model Package Group"
  type        = string
  default     = "my-model-group"
}

# -----------------------------------------------------------------------------
# SageMaker Pipeline Variables
# -----------------------------------------------------------------------------

variable "mlops_pipeline_name" {
  description = "Name of the SageMaker Pipeline"
  type        = string
  default     = "training-pipeline"
}

variable "mlops_pipeline_definition_s3_key" {
  description = "S3 key for the pipeline definition JSON file"
  type        = string
  default     = "pipelines/definition.json"
}

# -----------------------------------------------------------------------------
# SageMaker Model Monitoring Variables
# -----------------------------------------------------------------------------

variable "mlops_monitoring_schedule_expression" {
  description = "Schedule expression for model monitoring (cron format)"
  type        = string
  default     = "cron(0 * ? * * *)"
}

variable "mlops_monitoring_instance_type" {
  description = "Instance type for monitoring jobs"
  type        = string
  default     = "ml.m5.large"
}

variable "mlops_monitoring_instance_count" {
  description = "Number of instances for monitoring jobs"
  type        = number
  default     = 1
}


# =============================================================================
# Security & Compliance Variables
# =============================================================================

variable "deploy_kms" {
  description = "Whether to deploy KMS key for encryption"
  type        = bool
  default     = false
}

variable "deploy_cloudtrail" {
  description = "Whether to deploy CloudTrail for audit logging"
  type        = bool
  default     = false
}

variable "deploy_vpc_flow_logs" {
  description = "Whether to deploy VPC Flow Logs"
  type        = bool
  default     = false
}

variable "cloudtrail_log_retention_days" {
  description = "CloudTrail CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "cloudtrail_log_archive_days" {
  description = "Days before archiving CloudTrail S3 logs to Glacier"
  type        = number
  default     = 90
}

variable "cloudtrail_log_expiration_days" {
  description = "Days before deleting CloudTrail S3 logs"
  type        = number
  default     = 365
}

variable "vpc_flow_logs_retention_days" {
  description = "VPC Flow Logs CloudWatch retention in days"
  type        = number
  default     = 90
}

# =============================================================================
# AWS Backup Variables
# =============================================================================

variable "deploy_backup" {
  description = "Whether to deploy AWS Backup for RDS and other resources"
  type        = bool
  default     = true
}

variable "backup_daily_schedule" {
  description = "Cron expression for daily backup (UTC)"
  type        = string
  default     = "cron(0 5 ? * * *)" # 5 AM UTC daily
}

variable "backup_daily_retention_days" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 35
}

variable "backup_enable_weekly" {
  description = "Enable weekly backup rule"
  type        = bool
  default     = true
}

variable "backup_weekly_retention_days" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 90
}

variable "backup_enable_monthly" {
  description = "Enable monthly backup rule"
  type        = bool
  default     = true
}

variable "backup_monthly_retention_days" {
  description = "Number of days to retain monthly backups"
  type        = number
  default     = 365
}

# =============================================================================
# SageMaker CodeBuild Variables
# =============================================================================

variable "deploy_sagemaker_codebuild" {
  description = "Whether to deploy CodeBuild projects for SageMaker container build and model deploy"
  type        = bool
  default     = false
}

variable "sagemaker_codebuild_compute_type" {
  description = "CodeBuild compute type for SageMaker container builds"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "sagemaker_codebuild_image" {
  description = "CodeBuild Docker image for SageMaker builds"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}


# =============================================================================
# AWS Glue Variables
# =============================================================================

variable "deploy_glue" {
  description = "Whether to deploy AWS Glue for ETL"
  type        = bool
  default     = false
}

variable "glue_database_name" {
  description = "Glue catalog database name"
  type        = string
  default     = "mlops-data"
}

variable "glue_create_crawler" {
  description = "Whether to create a Glue crawler"
  type        = bool
  default     = false
}

variable "glue_crawler_name" {
  description = "Glue crawler name"
  type        = string
  default     = "data-crawler"
}

variable "glue_crawler_schedule" {
  description = "Cron schedule for crawler"
  type        = string
  default     = null
}

variable "glue_crawler_s3_targets" {
  description = "List of S3 targets for crawler"
  type = list(object({
    path       = string
    exclusions = optional(list(string), [])
  }))
  default = []
}

variable "glue_create_etl_job" {
  description = "Whether to create a Glue ETL job"
  type        = bool
  default     = false
}

variable "glue_job_name" {
  description = "Glue ETL job name"
  type        = string
  default     = "etl-job"
}

variable "glue_job_script_location" {
  description = "S3 path to the ETL script"
  type        = string
  default     = null
}

variable "glue_version" {
  description = "Glue version"
  type        = string
  default     = "4.0"
}

variable "glue_job_worker_type" {
  description = "Worker type (Standard, G.1X, G.2X)"
  type        = string
  default     = "G.1X"
}

variable "glue_job_number_of_workers" {
  description = "Number of workers"
  type        = number
  default     = 2
}

variable "glue_job_timeout" {
  description = "Job timeout in minutes"
  type        = number
  default     = 60
}

variable "glue_create_connection" {
  description = "Whether to create a Glue connection"
  type        = bool
  default     = false
}

variable "glue_connection_name" {
  description = "Glue connection name"
  type        = string
  default     = "jdbc-connection"
}

variable "glue_connection_type" {
  description = "Connection type (JDBC, KAFKA, MONGODB, NETWORK)"
  type        = string
  default     = "JDBC"
}

variable "glue_connection_properties" {
  description = "Connection properties"
  type        = map(string)
  default     = {}
}

variable "glue_enable_delta_lake" {
  description = "Enable Delta Lake support for Glue jobs (read/write Delta tables)"
  type        = bool
  default     = true
}

# =============================================================================
# API Gateway Variables
# =============================================================================

variable "deploy_api_gateway" {
  description = "Whether to deploy API Gateway for inference API"
  type        = bool
  default     = false
}

variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
  default     = "inference"
}

variable "api_gateway_endpoint_type" {
  description = "API endpoint type (REGIONAL, EDGE, PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

variable "api_gateway_stage_name" {
  description = "Deployment stage name"
  type        = string
  default     = "v1"
}

variable "api_gateway_throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 100
}

variable "api_gateway_throttling_rate_limit" {
  description = "Throttling rate limit (requests per second)"
  type        = number
  default     = 50
}

variable "api_gateway_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "api_gateway_enable_cors" {
  description = "Enable CORS"
  type        = bool
  default     = true
}

variable "api_gateway_require_api_key" {
  description = "Require API key for requests"
  type        = bool
  default     = false
}

# =============================================================================
# WAF Variables
# =============================================================================

variable "deploy_waf" {
  description = "Whether to deploy AWS WAF for API Gateway"
  type        = bool
  default     = true
}

variable "waf_enable_sql_injection_protection" {
  description = "Enable AWS Managed SQL injection protection rules"
  type        = bool
  default     = true
}

variable "waf_enable_rate_limiting" {
  description = "Enable rate limiting rule"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5 minutes per IP"
  type        = number
  default     = 2000
}

variable "waf_enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "waf_log_retention_days" {
  description = "WAF CloudWatch log retention in days"
  type        = number
  default     = 30
}

# =============================================================================
# VPC Variables
# =============================================================================

variable "create_vpc" {
  description = "Whether to create a new VPC or use existing one"
  type        = bool
  default     = false
}

variable "vpc_cidr_block" {
  description = "CIDR block for new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.11.0/24"
}

variable "create_nat_gateway" {
  description = "Create NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "public_subnet_id" {
  description = "Existing public subnet ID for NAT Gateway. Required when create_vpc = false and create_nat_gateway = true"
  type        = string
  default     = null
}

# =============================================================================
# Security Group Egress Control
# =============================================================================

variable "restrict_egress_to_vpc" {
  description = "Restrict security group egress to VPC CIDR only (recommended for production). If false, allows 0.0.0.0/0"
  type        = bool
  default     = true
}

variable "egress_cidr_blocks" {
  description = "Custom CIDR blocks for egress rules. If empty, uses VPC CIDR when restrict_egress_to_vpc=true, or 0.0.0.0/0 when false"
  type        = list(string)
  default     = []
}


# =============================================================================
# AWS Location Service Variables
# =============================================================================

variable "deploy_location_service" {
  description = "Whether to deploy AWS Location Service"
  type        = bool
  default     = false
}

variable "location_create_place_index" {
  description = "Create Place Index for geocoding"
  type        = bool
  default     = true
}

variable "location_create_map" {
  description = "Create Map resource"
  type        = bool
  default     = true
}

variable "location_create_tracker" {
  description = "Create Tracker for device tracking"
  type        = bool
  default     = false
}

variable "location_create_geofence_collection" {
  description = "Create Geofence Collection"
  type        = bool
  default     = false
}

variable "location_create_route_calculator" {
  description = "Create Route Calculator"
  type        = bool
  default     = false
}

variable "location_data_source" {
  description = "Data source provider: Esri or Here"
  type        = string
  default     = "Esri"
}

variable "location_service_region" {
  description = "Region for AWS Location Service (not available in all regions)"
  type        = string
  default     = "us-east-1"
}


# =============================================================================
# Transit Gateway Variables
# =============================================================================

variable "deploy_transit_gateway_attachment" {
  description = "Whether to attach VPC to Transit Gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to attach to (provided by Landing Zone team)"
  type        = string
  default     = null
}

variable "tgw_destination_cidr" {
  description = "Destination CIDR for TGW routes (e.g., on-premises or other VPCs)"
  type        = string
  default     = "10.0.0.0/8"
}

# =============================================================================
# AWS Config Variables
# =============================================================================

variable "deploy_aws_config" {
  description = "Whether to deploy AWS Config for compliance monitoring"
  type        = bool
  default     = false
}

variable "config_delivery_frequency" {
  description = "Config snapshot delivery frequency"
  type        = string
  default     = "TwentyFour_Hours"
}

variable "config_log_retention_days" {
  description = "Days to retain Config logs in S3"
  type        = number
  default     = 365
}

variable "config_enable_managed_rules" {
  description = "Enable AWS managed Config rules for compliance"
  type        = bool
  default     = true
}


# =============================================================================
# SageMaker Training Variables
# =============================================================================

variable "deploy_sagemaker_training" {
  description = "Whether to deploy SageMaker Training workflow"
  type        = bool
  default     = false
}

variable "training_image" {
  description = "Docker image URI for training"
  type        = string
  default     = null
}

variable "training_instance_type" {
  description = "Instance type for training"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "training_instance_count" {
  description = "Number of training instances"
  type        = number
  default     = 1
}

variable "training_volume_size" {
  description = "EBS volume size in GB for training"
  type        = number
  default     = 50
}

variable "enable_scheduled_training" {
  description = "Enable scheduled training jobs"
  type        = bool
  default     = false
}

variable "training_schedule" {
  description = "Cron expression for scheduled training"
  type        = string
  default     = "cron(0 0 ? * SUN *)"
}


# =============================================================================
# EC2 Test Instance Variables
# =============================================================================

variable "deploy_test_instance" {
  description = "Deploy EC2 test instance for VPC endpoint verification"
  type        = bool
  default     = false
}

variable "test_instance_type" {
  description = "Instance type for test EC2"
  type        = string
  default     = "t3.micro"
}


# =============================================================================
# SageMaker Studio Variables
# =============================================================================

variable "deploy_sagemaker_studio" {
  description = "Whether to deploy SageMaker Studio Domain"
  type        = bool
  default     = false
}

variable "studio_auth_mode" {
  description = "Studio authentication mode (IAM or SSO)"
  type        = string
  default     = "IAM"
}

variable "studio_default_instance_type" {
  description = "Default notebook instance type for Studio"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "studio_user_profiles" {
  description = "List of Studio user profiles to create"
  type = list(object({
    name                   = string
    execution_role_arn     = optional(string)
    jupyter_instance_type  = optional(string)
    notebook_instance_type = optional(string)
  }))
  default = []
}

# =============================================================================
# Permissions Boundary Variables
# =============================================================================

variable "data_bucket_name" {
  description = "Name of the data S3 bucket (must be globally unique)"
  type        = string
}

variable "enable_permissions_boundary" {
  description = "Whether to attach a permissions boundary to IAM roles. Set to false if the account does not use permissions boundaries."
  type        = bool
  default     = false
}

variable "permissions_boundary_policy_name" {
  description = "Name of the IAM permissions boundary policy (without ARN prefix)"
  type        = string
  default     = "SWOMasterPermissionsBoundary"
}
