
locals {
  aws_lmi = "${var.lmi_container_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/djl-inference:${var.lmi_container_version}"
}

module "sagemaker_endpoint_vision" {
  count  = var.deploy_vision_model ? 1 : 0
  source = "../../modules/sagemaker-endpoint"

  create_endpoint        = var.create_endpoint
  name_prefix            = var.name_prefix
  environment            = var.environment
  model_name             = var.vision_model_name
  instance_type          = var.vision_instance_type
  initial_instance_count = var.initial_instance_count
  enable_auto_schedule   = var.schedule_on_off_vision_endpoint
  model_bucket_name      = module.s3_model_storage.bucket_name
  model_bucket_arn       = module.s3_model_storage.bucket_arn

  enable_autoscaling         = var.enable_autoscaling_vision
  min_instance_count         = var.vision_min_instance_count
  max_instance_count         = var.vision_max_instance_count
  target_concurrent_requests = var.target_concurrent_requests

  container_image = var.custom_container_image != "" ? var.custom_container_image : local.aws_lmi
  container_environment = {
    HF_MODEL_ID              = "/opt/ml/model"
    OPTION_TRUST_REMOTE_CODE = "true"
    OPTION_DTYPE             = "auto"

    OPTION_MAX_MODEL_LEN          = var.max_model_len
    OPTION_GPU_MEMORY_UTILIZATION = "0.90"
    TENSOR_PARALLEL_DEGREE        = var.tensor_parallel_degree

    SERVING_FEATURES = "vllm"
    OPTION_ENGINE    = "Python"

    OPTION_DISABLE_LOG_REQUESTS = "true"
  }

  model_s3_key       = var.vision_model_s3_key
  execution_role_arn = module.sagemaker_role.role_arn
  security_group_ids = [module.sagemaker_sg.security_group_id]
  subnet_ids         = local.subnet_ids

  depends_on = [
    module.s3_model_storage,
    module.vpc_endpoints,
    module.sagemaker_sg,
    time_sleep.wait_for_iam_propagation
  ]
}

module "sagemaker_endpoint_text" {
  count  = var.deploy_text_model ? 1 : 0
  source = "../../modules/sagemaker-endpoint"

  create_endpoint        = var.create_endpoint
  name_prefix            = var.name_prefix
  environment            = var.environment
  model_name             = var.text_model_name
  instance_type          = var.text_instance_type
  initial_instance_count = var.initial_instance_count
  enable_auto_schedule   = var.schedule_on_off_text_endpoint
  model_bucket_name      = module.s3_model_storage.bucket_name
  model_bucket_arn       = module.s3_model_storage.bucket_arn

  enable_autoscaling         = var.enable_autoscaling_text
  min_instance_count         = var.text_min_instance_count
  max_instance_count         = var.text_max_instance_count
  target_concurrent_requests = var.target_concurrent_requests

  container_image = var.custom_container_image != "" ? var.custom_container_image : local.aws_lmi
  container_environment = {
    HF_MODEL_ID                    = "/opt/ml/model"
    OPTION_ASYNC_MODE              = "true"
    OPTION_ENABLE_AUTO_TOOL_CHOICE = "true"
    OPTION_ENTRYPOINT              = "djl_python.lmi_vllm.vllm_async_service"
    OPTION_ROLLING_BATCH           = "disable"
    OPTION_TOOL_CALL_PARSER        = "hermes"
    SERVING_FEATURES               = "vllm"
    OPTION_GPU_MEMORY_UTILIZATION  = "0.80"
    TENSOR_PARALLEL_DEGREE         = var.tensor_parallel_degree
    OPTION_ENGINE                  = "Python"
    OPTION_ENABLE_EXPERT_PARALLEL  = var.is_moe_text_model ? var.tensor_parallel_degree > 1 ? "true" : "false" : "false"
    OPTION_TRUST_REMOTE_CODE       = "true"
    OPTION_DTYPE                   = "auto"
    OPTION_MAX_MODEL_LEN           = var.max_model_len
    OPTION_MAX_BATCHED_LEN         = var.max_batched_len
    OPTION_USE_CUDA_GRAPH          = "true"
    SERVING_FAIL_FAST              = "true"
    OPTION_KV_CACHE_MEMORY         = "14991869440"

    OPTION_MAX_NUM_BATCHED_TOKENS = var.max_batched_len

    OPTION_ENABLE_PREFIX_CACHING  = "true"
    OPTION_ENABLE_CHUNKED_PREFILL = "false"
    OPTION_DISABLE_LOG_REQUESTS   = "true"
  }

  model_s3_key       = var.text_model_s3_key
  execution_role_arn = module.sagemaker_role.role_arn
  security_group_ids = [module.sagemaker_sg.security_group_id]
  subnet_ids         = local.subnet_ids

  depends_on = [
    module.s3_model_storage,
    module.vpc_endpoints,
    module.sagemaker_sg,
    time_sleep.wait_for_iam_propagation
  ]
}


# =============================================================================
# SageMaker Studio Domain
# =============================================================================
module "sagemaker_studio" {
  count  = var.deploy_sagemaker_studio ? 1 : 0
  source = "../../modules/sagemaker-studio"

  name_prefix        = var.name_prefix
  environment        = var.environment
  vpc_id             = local.vpc_id
  subnet_ids         = local.subnet_ids
  security_group_ids = [module.sagemaker_sg.security_group_id]
  execution_role_arn = module.sagemaker_role.role_arn

  auth_mode             = var.studio_auth_mode
  default_instance_type = var.studio_default_instance_type
  s3_output_path        = "s3://${module.s3_model_storage.bucket_name}/studio-outputs/"
  retain_efs            = var.environment == "prod"

  user_profiles = var.studio_user_profiles

  tags = var.tags

  depends_on = [
    module.vpc_endpoints,
    time_sleep.wait_for_iam_propagation
  ]
}
