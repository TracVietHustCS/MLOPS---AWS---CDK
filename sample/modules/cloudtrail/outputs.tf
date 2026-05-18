output "trail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.this.arn
}

output "trail_name" {
  description = "CloudTrail name"
  value       = aws_cloudtrail.this.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.trail.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.trail.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.arn
}
