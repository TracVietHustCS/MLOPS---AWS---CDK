output "job_definition_name" {
  description = "Name of the data quality job definition"
  value       = aws_sagemaker_data_quality_job_definition.data_quality.name
}

output "job_definition_arn" {
  description = "ARN of the data quality job definition"
  value       = aws_sagemaker_data_quality_job_definition.data_quality.arn
}

output "monitoring_schedule_name" {
  description = "Name of the monitoring schedule"
  value       = try(aws_sagemaker_monitoring_schedule.schedule[0].name, null)
}

output "monitoring_schedule_arn" {
  description = "ARN of the monitoring schedule"
  value       = try(aws_sagemaker_monitoring_schedule.schedule[0].arn, null)
}

output "endpoint_name" {
  description = "Name of the monitored endpoint"
  value       = var.endpoint_name
}

output "output_s3_uri" {
  description = "S3 URI where monitoring results are stored"
  value       = var.output_s3_uri
}

output "role_arn" {
  description = "IAM role ARN used by the monitoring job"
  value       = var.role_arn
}
