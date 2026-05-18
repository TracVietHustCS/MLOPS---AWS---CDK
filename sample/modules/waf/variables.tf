variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "scope" {
  description = "WAF scope (REGIONAL for API Gateway/ALB, CLOUDFRONT for CloudFront)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be REGIONAL or CLOUDFRONT."
  }
}

# Protection rules
variable "enable_sql_injection_protection" {
  description = "Enable AWS Managed SQL injection protection rules"
  type        = bool
  default     = true
}

variable "enable_rate_limiting" {
  description = "Enable rate limiting rule"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Maximum requests per 5 minutes per IP"
  type        = number
  default     = 2000
}

# Association
variable "enable_api_gateway_association" {
  description = "Enable WAF association with API Gateway"
  type        = bool
  default     = false
}

variable "api_gateway_stage_arn" {
  description = "ARN of API Gateway stage to associate with WAF"
  type        = string
  default     = null
}

# Logging
variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
