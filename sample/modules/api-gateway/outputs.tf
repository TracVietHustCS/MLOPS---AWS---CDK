output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_arn" {
  description = "API Gateway REST API ARN"
  value       = aws_api_gateway_rest_api.this.arn
}

output "api_name" {
  description = "API Gateway REST API name"
  value       = aws_api_gateway_rest_api.this.name
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_arn" {
  description = "API Gateway stage ARN (for WAF association)"
  value       = aws_api_gateway_stage.this.arn
}

output "api_key_id" {
  description = "API key ID"
  value       = var.require_api_key ? aws_api_gateway_api_key.this[0].id : null
}

output "api_key_value" {
  description = "API key value"
  value       = var.require_api_key ? aws_api_gateway_api_key.this[0].value : null
  sensitive   = true
}

output "vpc_link_id" {
  description = "VPC Link ID"
  value       = var.create_vpc_link ? aws_api_gateway_vpc_link.this[0].id : null
}


output "cognito_authorizer_id" {
  description = "Cognito Authorizer ID"
  value       = var.enable_cognito_authorizer ? aws_api_gateway_authorizer.cognito[0].id : null
}
