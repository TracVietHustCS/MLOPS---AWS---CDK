output "model_package_group_name" {
  description = "Name of the SageMaker Model Package Group"
  value       = aws_sagemaker_model_package_group.model_package_group.model_package_group_name
}

output "model_package_group_arn" {
  description = "ARN of the SageMaker Model Package Group"
  value       = aws_sagemaker_model_package_group.model_package_group.arn
}

output "model_package_group_id" {
  description = "ID of the SageMaker Model Package Group"
  value       = aws_sagemaker_model_package_group.model_package_group.id
}
