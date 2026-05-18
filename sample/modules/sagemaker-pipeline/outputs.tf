output "pipeline_name" {
  description = "Name of the SageMaker pipeline"
  value       = aws_sagemaker_pipeline.pipeline.pipeline_name
}

output "pipeline_arn" {
  description = "ARN of the SageMaker pipeline"
  value       = aws_sagemaker_pipeline.pipeline.arn
}

output "pipeline_display_name" {
  description = "Display name of the SageMaker pipeline"
  value       = aws_sagemaker_pipeline.pipeline.pipeline_display_name
}

output "role_arn" {
  description = "IAM role ARN used by the pipeline"
  value       = var.role_arn
}
