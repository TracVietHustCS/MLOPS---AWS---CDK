# =============================================================================
# API Gateway + Lambda
# =============================================================================
# Flow: External Client → API Gateway → Lambda → Response
# Endpoints:
#   - GET/POST /v1/test - Test connection (returns success)
#   - POST /v1/inference - Model inference (when SageMaker deployed)
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda IAM Role
# -----------------------------------------------------------------------------
module "api_lambda_role" {
  source = "../../modules/iam-role"
  count  = var.deploy_api_gateway ? 1 : 0

  role_name            = "${var.name_prefix}-${var.environment}-api-lambda"
  permissions_boundary = local.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  inline_policies = {
    logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        }
      ]
    })
    location = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "geo:ListPlaceIndexes",
            "geo:SearchPlaceIndexForText",
          ]
          Resource = "arn:aws:geo:${var.aws_region}:${data.aws_caller_identity.current.account_id}:place-index/*"
        },
        {
          Effect   = "Allow"
          Action   = "geo:ListPlaceIndexes"
          Resource = "*"
        }
      ]
    })
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Lambda Function - API
# -----------------------------------------------------------------------------
module "api_lambda" {
  source = "../../modules/lambda"
  count  = var.deploy_api_gateway ? 1 : 0

  name_prefix     = var.name_prefix
  environment     = var.environment
  function_name   = "api"
  source_path     = "../../lambda_functions/api-test"
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.12"
  timeout         = 30
  memory_size     = 128
  lambda_role_arn = module.api_lambda_role[0].role_arn

  environment_variables = {
    ENVIRONMENT = var.environment
    REGION      = var.aws_region
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# API Gateway
# -----------------------------------------------------------------------------
module "api_gateway" {
  source = "../../modules/api-gateway"
  count  = var.deploy_api_gateway ? 1 : 0

  name_prefix = var.name_prefix
  environment = var.environment
  api_name    = var.api_gateway_name

  endpoint_type = var.api_gateway_endpoint_type
  stage_name    = var.api_gateway_stage_name

  # Lambda Integration
  enable_lambda_integration = true
  lambda_function_arn       = module.api_lambda[0].lambda_function_arn
  lambda_function_name      = module.api_lambda[0].lambda_function_name

  # Throttling
  throttling_burst_limit = var.api_gateway_throttling_burst_limit
  throttling_rate_limit  = var.api_gateway_throttling_rate_limit

  # Logging
  enable_access_logging     = true
  access_log_retention_days = var.api_gateway_log_retention_days

  # CORS
  enable_cors = var.api_gateway_enable_cors

  # API Key
  require_api_key = var.api_gateway_require_api_key

  tags = var.tags
}
