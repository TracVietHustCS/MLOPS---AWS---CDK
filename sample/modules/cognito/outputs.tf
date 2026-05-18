output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_name" {
  description = "Cognito User Pool name"
  value       = aws_cognito_user_pool.this.name
}

output "spa_client_id" {
  description = "SPA App Client ID (no secret, for IdToken)"
  value       = aws_cognito_user_pool_client.spa.id
}

output "confidential_client_id" {
  description = "Confidential App Client ID (with secret, for AccessToken)"
  value       = var.create_resource_server ? aws_cognito_user_pool_client.confidential[0].id : null
}

output "confidential_client_secret" {
  description = "Confidential App Client Secret"
  value       = var.create_resource_server ? aws_cognito_user_pool_client.confidential[0].client_secret : null
  sensitive   = true
}
