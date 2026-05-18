# =============================================================================
# AWS Config Outputs
# =============================================================================

output "recorder_id" {
  description = "Config Recorder ID"
  value       = aws_config_configuration_recorder.this.id
}

output "delivery_channel_id" {
  description = "Delivery Channel ID"
  value       = aws_config_delivery_channel.this.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for Config logs"
  value       = var.create_s3_bucket ? aws_s3_bucket.config[0].id : var.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for Config logs"
  value       = var.create_s3_bucket ? aws_s3_bucket.config[0].arn : null
}

output "role_arn" {
  description = "IAM role ARN for Config"
  value       = aws_iam_role.config.arn
}

output "config_rules" {
  description = "List of Config rule names"
  value       = [for rule in aws_config_config_rule.managed : rule.name]
}
