output "endpoint_name" {
  description = "SageMaker endpoint name"
  value       = try(aws_sagemaker_endpoint.endpoint[0].name, "${var.name_prefix}-${var.environment}-${var.model_name}")
}

output "endpoint_arn" {
  description = "SageMaker endpoint ARN"
  value       = try(aws_sagemaker_endpoint.endpoint[0].arn, "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint/${var.name_prefix}-${var.environment}-${var.model_name}")
}

output "model_name" {
  description = "SageMaker model name"
  value       = aws_sagemaker_model.model.name
}

output "execution_role_arn" {
  description = "IAM execution role ARN"
  value       = var.execution_role_arn
}

output "autoscaling_target_id" {
  description = "Autoscaling target resource ID"
  value       = try(aws_appautoscaling_target.endpoint[0].id, null)
}

output "autoscaling_policy_name" {
  description = "Autoscaling policy name (concurrent requests-based)"
  value       = try(aws_appautoscaling_policy.endpoint_concurrent[0].name, null)
}

output "autoscaling_enabled" {
  description = "Whether autoscaling is enabled for this endpoint"
  value       = var.enable_autoscaling && var.create_endpoint
}
