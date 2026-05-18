output "sagemaker_runtime_endpoint_id" {
  description = "SageMaker Runtime VPC endpoint ID"
  value       = try(aws_vpc_endpoint.sagemaker_runtime[0].id, null)
}

output "sagemaker_runtime_dns_entry" {
  description = "SageMaker Runtime VPC endpoint DNS entry"
  value       = try(aws_vpc_endpoint.sagemaker_runtime[0].dns_entry, null)
}

output "secretsmanager_endpoint_id" {
  description = "Secrets Manager VPC endpoint ID"
  value       = try(aws_vpc_endpoint.secretsmanager[0].id, null)
}

output "logs_endpoint_id" {
  description = "CloudWatch Logs VPC endpoint ID"
  value       = try(aws_vpc_endpoint.logs[0].id, null)
}

output "s3_gateway_endpoint_id" {
  description = "S3 Gateway VPC endpoint ID"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "s3_interface_endpoint_id" {
  description = "S3 Interface VPC endpoint ID"
  value       = try(aws_vpc_endpoint.s3_interface[0].id, null)
}

output "execute_api_endpoint_id" {
  description = "API Gateway (execute-api) VPC endpoint ID"
  value       = try(aws_vpc_endpoint.execute_api[0].id, null)
}
