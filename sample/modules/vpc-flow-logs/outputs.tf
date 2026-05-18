output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.this.id
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN (if using CloudWatch destination)"
  value       = var.log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN (if using S3 destination)"
  value       = var.log_destination_type == "s3" ? aws_s3_bucket.flow_logs[0].arn : null
}
