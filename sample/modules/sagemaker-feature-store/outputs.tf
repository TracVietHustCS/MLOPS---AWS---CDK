output "feature_group_name" {
  description = "Name of the SageMaker Feature Group"
  value       = aws_sagemaker_feature_group.feature_group.feature_group_name
}

output "feature_group_arn" {
  description = "ARN of the SageMaker Feature Group"
  value       = aws_sagemaker_feature_group.feature_group.arn
}

output "feature_group_id" {
  description = "ID of the SageMaker Feature Group"
  value       = aws_sagemaker_feature_group.feature_group.id
}

output "online_store_enabled" {
  description = "Whether online store is enabled"
  value       = var.enable_online_store
}

output "offline_store_enabled" {
  description = "Whether offline store is enabled"
  value       = var.enable_offline_store
}

output "offline_store_s3_uri" {
  description = "S3 URI for offline store data"
  value       = var.offline_store_s3_uri
}

output "record_identifier_name" {
  description = "Name of the record identifier feature"
  value       = var.record_identifier_name
}

output "event_time_name" {
  description = "Name of the event time feature"
  value       = var.event_time_name
}
