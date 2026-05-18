# =============================================================================
# API Gateway Module
# =============================================================================
# Nhận request từ các hệ thống bên ngoài, chuẩn hóa request và gửi event tới
# Lambda để xử lý đồng thời gửi các response ra bên ngoài từ Lambda
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# IAM Role for API Gateway CloudWatch Logs (Account-level setting)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "api_gateway_cloudwatch" {
  count = var.enable_access_logging ? 1 : 0
  name  = "${var.name_prefix}-${var.environment}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  count = var.enable_access_logging ? 1 : 0
  name  = "cloudwatch-logs"
  role  = aws_iam_role.api_gateway_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ]
      Resource = "*"
    }]
  })
}

# Set the CloudWatch role ARN at account level
resource "aws_api_gateway_account" "this" {
  count               = var.enable_access_logging ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch[0].arn
}

# -----------------------------------------------------------------------------
# REST API
# -----------------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.name_prefix}-${var.environment}-${var.api_name}"
  description = var.api_description

  endpoint_configuration {
    types            = [var.endpoint_type]
    vpc_endpoint_ids = var.endpoint_type == "PRIVATE" ? var.vpc_endpoint_ids : null
    ip_address_type  = var.endpoint_type == "PRIVATE" ? "dualstack" : null
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.api_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Resource Policy (required for PRIVATE API Gateway)
# -----------------------------------------------------------------------------
resource "aws_api_gateway_rest_api_policy" "this" {
  count       = var.endpoint_type == "PRIVATE" ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "${aws_api_gateway_rest_api.this.execution_arn}/*"
        Condition = {
          StringNotEquals = {
            "aws:sourceVpce" = var.vpc_endpoint_ids
          }
        }
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "${aws_api_gateway_rest_api.this.execution_arn}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Cognito Authorizer
# -----------------------------------------------------------------------------
resource "aws_api_gateway_authorizer" "cognito" {
  count         = var.enable_cognito_authorizer ? 1 : 0
  name          = "cognito-auth"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]

  identity_source = "method.request.header.Authorization"
}

# -----------------------------------------------------------------------------
# Resource: /inference
# -----------------------------------------------------------------------------
resource "aws_api_gateway_resource" "inference" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "inference"
}

# -----------------------------------------------------------------------------
# Resource: /test (for connection testing)
# -----------------------------------------------------------------------------
resource "aws_api_gateway_resource" "test" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "test"
}

# GET /test
resource "aws_api_gateway_method" "test_get" {
  count            = var.enable_test_endpoint ? 1 : 0
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.test.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "test_get_lambda" {
  count                   = var.enable_test_endpoint ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.test.id
  http_method             = aws_api_gateway_method.test_get[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

# POST /test
resource "aws_api_gateway_method" "test_post" {
  count            = var.enable_test_endpoint ? 1 : 0
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.test.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "test_post_lambda" {
  count                   = var.enable_test_endpoint ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.test.id
  http_method             = aws_api_gateway_method.test_post[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

# OPTIONS /test (CORS)
resource "aws_api_gateway_method" "test_options" {
  count         = var.enable_cors && var.enable_test_endpoint ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.test.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_options" {
  count       = var.enable_cors && var.enable_test_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test_options[0].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "test_options_200" {
  count       = var.enable_cors && var.enable_test_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test_options[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "test_options" {
  count       = var.enable_cors && var.enable_test_endpoint ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test_options[0].http_method
  status_code = aws_api_gateway_method_response.test_options_200[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", var.cors_allow_headers)}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${join(",", var.cors_allow_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${join(",", var.cors_allow_origins)}'"
  }
}


# -----------------------------------------------------------------------------
# Method: POST /inference
# -----------------------------------------------------------------------------
resource "aws_api_gateway_method" "inference_post" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.inference.id
  http_method      = "POST"
  authorization    = var.enable_cognito_authorizer ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id    = var.enable_cognito_authorizer ? aws_api_gateway_authorizer.cognito[0].id : null
  api_key_required = var.require_api_key
}

# Lambda Integration - Route to submit lambda if async API enabled, otherwise to main lambda
resource "aws_api_gateway_integration" "inference_lambda" {
  count                   = var.enable_lambda_integration ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.inference.id
  http_method             = aws_api_gateway_method.inference_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = var.enable_async_api && var.submit_lambda_function_arn != null ? "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.submit_lambda_function_arn}/invocations" : "arn:aws:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
  content_handling        = "CONVERT_TO_TEXT"
}

# Lambda Permission for main lambda (only when not using async API)
resource "aws_lambda_permission" "api_gateway" {
  count         = var.enable_lambda_integration && !var.enable_async_api ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Lambda Permission for submit lambda (async API)
resource "aws_lambda_permission" "api_gateway_submit" {
  count         = var.enable_lambda_integration && var.enable_async_api && var.submit_lambda_function_name != null ? 1 : 0
  statement_id  = "AllowAPIGatewayInvokeSubmit"
  action        = "lambda:InvokeFunction"
  function_name = var.submit_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Method Response
resource "aws_api_gateway_method_response" "inference_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.inference.id
  http_method = aws_api_gateway_method.inference_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = var.enable_cors ? {
    "method.response.header.Access-Control-Allow-Origin" = true
  } : {}
}

# -----------------------------------------------------------------------------
# CORS: OPTIONS /inference
# -----------------------------------------------------------------------------
resource "aws_api_gateway_method" "inference_options" {
  count         = var.enable_cors ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.inference.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "inference_options" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.inference.id
  http_method = aws_api_gateway_method.inference_options[0].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "inference_options_200" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.inference.id
  http_method = aws_api_gateway_method.inference_options[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "inference_options" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.inference.id
  http_method = aws_api_gateway_method.inference_options[0].http_method
  status_code = aws_api_gateway_method_response.inference_options_200[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", var.cors_allow_headers)}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${join(",", var.cors_allow_methods)}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${join(",", var.cors_allow_origins)}'"
  }
}

# -----------------------------------------------------------------------------
# Deployment & Stage
# -----------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.inference.id,
      aws_api_gateway_method.inference_post.id,
      var.enable_lambda_integration,
      aws_api_gateway_resource.test.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.inference_post,
    aws_api_gateway_integration.inference_lambda,
    aws_api_gateway_method.test_get,
    aws_api_gateway_method.test_post,
    aws_api_gateway_integration.test_get_lambda,
    aws_api_gateway_integration.test_post_lambda
  ]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  description   = var.stage_description

  dynamic "access_log_settings" {
    for_each = var.enable_access_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_logs[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
      })
    }
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.api_name}-${var.stage_name}"
      Environment = var.environment
    },
    var.tags
  )

  # Must wait for account-level CloudWatch role to be set
  depends_on = [aws_api_gateway_account.this]
}

# Method Settings (Throttling)
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
    logging_level          = "INFO"
    metrics_enabled        = true
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "api_logs" {
  count             = var.enable_access_logging ? 1 : 0
  name              = "/aws/api-gateway/${var.name_prefix}-${var.environment}-${var.api_name}"
  retention_in_days = var.access_log_retention_days

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.api_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# API Key & Usage Plan (optional)
# -----------------------------------------------------------------------------
resource "aws_api_gateway_api_key" "this" {
  count   = var.require_api_key ? 1 : 0
  name    = "${var.name_prefix}-${var.environment}-${var.api_key_name}"
  enabled = true

  tags = var.tags
}

resource "aws_api_gateway_usage_plan" "this" {
  count = var.create_usage_plan ? 1 : 0
  name  = "${var.name_prefix}-${var.environment}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  quota_settings {
    limit  = var.usage_plan_quota_limit
    period = var.usage_plan_quota_period
  }

  throttle_settings {
    burst_limit = var.throttling_burst_limit
    rate_limit  = var.throttling_rate_limit
  }

  tags = var.tags
}

resource "aws_api_gateway_usage_plan_key" "this" {
  count         = var.require_api_key && var.create_usage_plan ? 1 : 0
  key_id        = aws_api_gateway_api_key.this[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[0].id
}

# -----------------------------------------------------------------------------
# VPC Link (for private integrations)
# -----------------------------------------------------------------------------
resource "aws_api_gateway_vpc_link" "this" {
  count       = var.create_vpc_link ? 1 : 0
  name        = "${var.name_prefix}-${var.environment}-vpc-link"
  target_arns = var.vpc_link_target_arns

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-vpc-link"
      Environment = var.environment
    },
    var.tags
  )
}
