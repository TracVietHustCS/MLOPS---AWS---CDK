# =============================================================================
# Lambda Functions
# =============================================================================
# Note: sagemaker-scheduler has been removed per customer request.
# API test Lambda is now in api.tf
# =============================================================================

# -----------------------------------------------------------------------------
# SageMaker Scheduler (DISABLED - kept for reference)
# -----------------------------------------------------------------------------
# Uncomment if you need automatic endpoint start/stop scheduling
# 
# module "sagemaker_scheduler" {
#   source = "../../modules/lambda"
#
#   name_prefix   = var.name_prefix
#   environment   = var.environment
#   function_name = "sagemaker-scheduler"
#   source_path   = "${path.root}/../../lambda_functions/sagemaker-scheduler"
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.12"
#   timeout       = 900
#
#   lambda_role_arn = module.scheduler_role.role_arn
#
#   environment_variables = {
#     TAG_KEY      = "AutoSchedule"
#     TAG_VALUE    = "true"
#     STATE_BUCKET = module.s3_model_storage.bucket_name
#   }
#
#   eventbridge_rules = var.enable_endpoint_scheduler ? {
#     sagemaker-stop = {
#       description         = "Stop SageMaker endpoints in the evening"
#       schedule_expression = var.scheduler_stop_cron
#       input = jsonencode({
#         action = "stop"
#       })
#     }
#     sagemaker-start = {
#       description         = "Start SageMaker endpoints in the morning"
#       schedule_expression = var.scheduler_start_cron
#       input = jsonencode({
#         action = "start"
#       })
#     }
#   } : {}
#
#   tags = var.tags
# }
