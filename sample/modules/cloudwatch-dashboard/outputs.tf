output "dashboard_arn" {
  description = "CloudWatch dashboard ARN"
  value       = aws_cloudwatch_dashboard.this.dashboard_arn
}

output "alarm_arns" {
  description = "Map of CloudWatch alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.alarms : k => v.arn }
}
