# =============================================================================
# SageMaker Training Outputs
# =============================================================================

output "state_machine_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.training.arn
}

output "state_machine_name" {
  description = "Step Functions state machine name"
  value       = aws_sfn_state_machine.training.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.training.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.training.arn
}

output "execution_role_arn" {
  description = "Step Functions execution role ARN"
  value       = var.execution_role_arn != null ? var.execution_role_arn : aws_iam_role.training[0].arn
}

output "scheduled_rule_arn" {
  description = "EventBridge scheduled rule ARN"
  value       = var.enable_scheduled_training ? aws_cloudwatch_event_rule.scheduled_training[0].arn : null
}
