output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for model artifacts"
  value       = module.s3_model_storage.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for model artifacts"
  value       = module.s3_model_storage.bucket_arn
}

output "model_upload_instructions" {
  description = "Instructions for uploading models"
  value       = <<-EOT
    Upload your models to S3 bucket: ${module.s3_model_storage.bucket_name}

    Vision Model (Qwen 2.5 VL 7B):
      python3 prepare_and_upload_model.py \
        --model-id "Qwen/Qwen2.5-VL-7B-Instruct" \
        --model-name "qwen2.5-vl-7b" \
        --bucket ${module.s3_model_storage.bucket_name} \
        --region ${var.aws_region}

    Text Model (Qwen 3 14B FP8):
      python3 prepare_and_upload_model.py \
        --model-id "Qwen/Qwen3-14B-FP8" \
        --model-name "qwen3-14b-fp8" \
        --bucket ${module.s3_model_storage.bucket_name} \
        --region ${var.aws_region}

    Then run: terraform apply
  EOT
}


# =============================================================================
# MLOps Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# RDS PostgreSQL Outputs
# -----------------------------------------------------------------------------

output "mlops_rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.deploy_mlops_rds ? module.mlops_rds_postgres[0].db_instance_endpoint : null
}

output "mlops_rds_address" {
  description = "RDS instance address"
  value       = var.deploy_mlops_rds ? module.mlops_rds_postgres[0].db_instance_address : null
}

output "mlops_rds_arn" {
  description = "RDS instance ARN"
  value       = var.deploy_mlops_rds ? module.mlops_rds_postgres[0].db_instance_arn : null
}

output "mlops_rds_database_name" {
  description = "RDS database name"
  value       = var.deploy_mlops_rds ? module.mlops_rds_postgres[0].database_name : null
}

output "mlops_rds_port" {
  description = "RDS instance port"
  value       = var.deploy_mlops_rds ? module.mlops_rds_postgres[0].db_instance_port : null
}

output "mlops_secrets_manager_secret_arns" {
  description = "Map of Secrets Manager secret ARNs"
  value       = var.deploy_mlops_rds ? module.mlops_secrets_manager[0].secret_arns : null
}

# -----------------------------------------------------------------------------
# SageMaker Feature Store Outputs
# -----------------------------------------------------------------------------

output "mlops_feature_group_name" {
  description = "Name of the SageMaker Feature Group"
  value       = var.deploy_mlops_feature_store ? module.mlops_feature_store[0].feature_group_name : null
}

output "mlops_feature_group_arn" {
  description = "ARN of the SageMaker Feature Group"
  value       = var.deploy_mlops_feature_store ? module.mlops_feature_store[0].feature_group_arn : null
}

output "mlops_feature_offline_store_s3_uri" {
  description = "S3 URI for Feature Store offline data"
  value       = var.deploy_mlops_feature_store ? module.mlops_feature_store[0].offline_store_s3_uri : null
}

# -----------------------------------------------------------------------------
# SageMaker Model Registry Outputs
# -----------------------------------------------------------------------------

output "mlops_model_registry_name" {
  description = "Name of the SageMaker Model Package Group"
  value       = var.deploy_mlops_model_registry ? module.mlops_model_registry[0].model_package_group_name : null
}

output "mlops_model_registry_arn" {
  description = "ARN of the SageMaker Model Package Group"
  value       = var.deploy_mlops_model_registry ? module.mlops_model_registry[0].model_package_group_arn : null
}

# -----------------------------------------------------------------------------
# SageMaker Pipeline Outputs
# -----------------------------------------------------------------------------

output "mlops_pipeline_name" {
  description = "Name of the SageMaker Pipeline"
  value       = var.deploy_mlops_pipeline ? module.mlops_pipeline[0].pipeline_name : null
}

output "mlops_pipeline_arn" {
  description = "ARN of the SageMaker Pipeline"
  value       = var.deploy_mlops_pipeline ? module.mlops_pipeline[0].pipeline_arn : null
}

# -----------------------------------------------------------------------------
# SageMaker Model Monitoring Outputs
# -----------------------------------------------------------------------------

output "mlops_monitoring_job_definition_name" {
  description = "Name of the monitoring job definition"
  value       = var.deploy_mlops_model_monitoring && (var.deploy_text_model || var.deploy_vision_model) ? module.mlops_model_monitoring[0].job_definition_name : null
}

output "mlops_monitoring_job_definition_arn" {
  description = "ARN of the monitoring job definition"
  value       = var.deploy_mlops_model_monitoring && (var.deploy_text_model || var.deploy_vision_model) ? module.mlops_model_monitoring[0].job_definition_arn : null
}

output "mlops_monitoring_schedule_name" {
  description = "Name of the monitoring schedule"
  value       = var.deploy_mlops_model_monitoring && (var.deploy_text_model || var.deploy_vision_model) ? module.mlops_model_monitoring[0].monitoring_schedule_name : null
}

output "mlops_monitoring_output_s3_uri" {
  description = "S3 URI for monitoring output"
  value       = var.deploy_mlops_model_monitoring && (var.deploy_text_model || var.deploy_vision_model) ? module.mlops_model_monitoring[0].output_s3_uri : null
}


# =============================================================================
# Security & Compliance Outputs
# =============================================================================

output "kms_key_s3_arn" {
  description = "KMS key ARN for S3"
  value       = var.deploy_kms ? module.kms_key_s3[0].key_arn : null
}

output "kms_key_rds_arn" {
  description = "KMS key ARN for RDS"
  value       = var.deploy_kms ? module.kms_key_rds[0].key_arn : null
}

output "kms_key_sagemaker_arn" {
  description = "KMS key ARN for SageMaker"
  value       = var.deploy_kms ? module.kms_key_sagemaker[0].key_arn : null
}

output "kms_key_logs_arn" {
  description = "KMS key ARN for CloudTrail/Logs"
  value       = var.deploy_kms ? module.kms_key_logs[0].key_arn : null
}

output "kms_key_ecr_arn" {
  description = "KMS key ARN for ECR/CodeBuild"
  value       = var.deploy_kms ? module.kms_key_ecr[0].key_arn : null
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = var.deploy_cloudtrail ? module.cloudtrail[0].trail_arn : null
}

output "cloudtrail_log_group" {
  description = "CloudTrail CloudWatch Log Group name"
  value       = var.deploy_cloudtrail ? module.cloudtrail[0].cloudwatch_log_group_name : null
}

output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = var.deploy_vpc_flow_logs ? module.vpc_flow_logs[0].flow_log_id : null
}

# =============================================================================
# SageMaker CodeBuild Outputs
# =============================================================================

output "sagemaker_codebuild_deploy_project" {
  description = "CodeBuild model deploy project name for SageMaker"
  value       = var.deploy_sagemaker_codebuild ? module.sagemaker_codebuild_deploy[0].project_name : null
}

# =============================================================================
# AWS Glue Outputs
# =============================================================================

output "glue_database_name" {
  description = "Glue catalog database name"
  value       = var.deploy_glue ? module.glue[0].database_name : null
}

output "glue_crawler_name" {
  description = "Glue crawler name"
  value       = var.deploy_glue && var.glue_create_crawler ? module.glue[0].crawler_name : null
}

output "glue_job_name" {
  description = "Glue ETL job name"
  value       = var.deploy_glue && var.glue_create_etl_job ? module.glue[0].job_name : null
}

# =============================================================================
# API Gateway Outputs
# =============================================================================

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = var.deploy_api_gateway ? module.api_gateway[0].invoke_url : null
}

output "api_gateway_api_id" {
  description = "API Gateway REST API ID"
  value       = var.deploy_api_gateway ? module.api_gateway[0].api_id : null
}

output "api_gateway_stage_name" {
  description = "API Gateway stage name"
  value       = var.deploy_api_gateway ? module.api_gateway[0].stage_name : null
}


# =============================================================================
# Security Group Outputs
# =============================================================================

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = module.lambda_sg.security_group_id
}

output "glue_security_group_id" {
  description = "Glue security group ID"
  value       = module.glue_sg.security_group_id
}

output "sagemaker_security_group_id" {
  description = "SageMaker security group ID"
  value       = module.sagemaker_sg.security_group_id
}

output "vpc_endpoints_security_group_id" {
  description = "VPC Endpoints security group ID"
  value       = module.vpc_endpoints_sg.security_group_id
}


# =============================================================================
# EC2 Test Instance Outputs
# =============================================================================

output "test_instance_id" {
  description = "Test EC2 instance ID"
  value       = var.deploy_test_instance ? module.ec2_test[0].instance_id : null
}

output "test_instance_private_ip" {
  description = "Test EC2 private IP"
  value       = var.deploy_test_instance ? module.ec2_test[0].private_ip : null
}

output "test_instance_ssm_command" {
  description = "SSM command to connect to test instance"
  value       = var.deploy_test_instance ? module.ec2_test[0].ssm_connect_command : null
}


# =============================================================================
# SageMaker Studio Outputs
# =============================================================================

output "sagemaker_studio_domain_id" {
  description = "SageMaker Studio Domain ID"
  value       = var.deploy_sagemaker_studio ? module.sagemaker_studio[0].domain_id : null
}

output "sagemaker_studio_url" {
  description = "SageMaker Studio Domain URL"
  value       = var.deploy_sagemaker_studio ? module.sagemaker_studio[0].domain_url : null
}
