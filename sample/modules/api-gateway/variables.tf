variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_name" {
  description = "API Gateway name suffix"
  type        = string
  default     = "inference"
}

variable "api_description" {
  description = "API description"
  type        = string
  default     = "MLOps Inference API Gateway"
}

variable "endpoint_type" {
  description = "API endpoint type (REGIONAL, EDGE, PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

# Stage
variable "stage_name" {
  description = "Deployment stage name"
  type        = string
  default     = "v1"
}

variable "stage_description" {
  description = "Stage description"
  type        = string
  default     = "Production stage"
}

# Lambda Integration
variable "enable_lambda_integration" {
  description = "Enable Lambda integration for API Gateway"
  type        = bool
  default     = false
}

variable "enable_test_endpoint" {
  description = "Enable /test GET/POST endpoints connected to main lambda"
  type        = bool
  default     = true
}

variable "lambda_function_arn" {
  description = "Lambda function ARN for integration"
  type        = string
  default     = null
}

variable "lambda_function_name" {
  description = "Lambda function name for permission"
  type        = string
  default     = null
}

# Async API - Submit Lambda for inference endpoint
variable "enable_async_api" {
  description = "Enable async API - route inference to submit lambda"
  type        = bool
  default     = false
}

variable "submit_lambda_function_arn" {
  description = "Submit Lambda function ARN for async inference"
  type        = string
  default     = null
}

variable "submit_lambda_function_name" {
  description = "Submit Lambda function name for permission"
  type        = string
  default     = null
}

# VPC Link (for private integrations)
variable "create_vpc_link" {
  description = "Whether to create VPC Link for private integrations"
  type        = bool
  default     = false
}

variable "vpc_link_target_arns" {
  description = "Target ARNs for VPC Link (NLB ARNs)"
  type        = list(string)
  default     = []
}

# Throttling
variable "throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "Throttling rate limit (requests per second)"
  type        = number
  default     = 50
}

# Logging
variable "enable_access_logging" {
  description = "Enable access logging"
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# CORS
variable "enable_cors" {
  description = "Enable CORS"
  type        = bool
  default     = true
}

variable "cors_allow_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allow_methods" {
  description = "Allowed methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]
}

variable "cors_allow_headers" {
  description = "Allowed headers for CORS"
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Api-Key"]
}

# API Key
variable "require_api_key" {
  description = "Require API key for requests"
  type        = bool
  default     = false
}

variable "api_key_name" {
  description = "API key name"
  type        = string
  default     = "default-key"
}

# Usage Plan
variable "create_usage_plan" {
  description = "Whether to create a usage plan"
  type        = bool
  default     = false
}

variable "usage_plan_quota_limit" {
  description = "Usage plan quota limit"
  type        = number
  default     = 10000
}

variable "usage_plan_quota_period" {
  description = "Usage plan quota period (DAY, WEEK, MONTH)"
  type        = string
  default     = "MONTH"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}




# Cognito Authorizer
variable "enable_cognito_authorizer" {
  description = "Enable Cognito User Pool authorizer for API methods"
  type        = bool
  default     = false
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for authorizer"
  type        = string
  default     = null
}

# Private API Gateway
variable "vpc_endpoint_ids" {
  description = "VPC Endpoint IDs for PRIVATE endpoint type"
  type        = list(string)
  default     = []
}
