output "domain_id" {
  description = "SageMaker Studio Domain ID"
  value       = aws_sagemaker_domain.this.id
}

output "domain_arn" {
  description = "SageMaker Studio Domain ARN"
  value       = aws_sagemaker_domain.this.arn
}

output "domain_url" {
  description = "SageMaker Studio Domain URL"
  value       = aws_sagemaker_domain.this.url
}

output "home_efs_file_system_id" {
  description = "EFS file system ID for home directories"
  value       = aws_sagemaker_domain.this.home_efs_file_system_id
}

output "user_profile_arns" {
  description = "Map of user profile names to ARNs"
  value       = { for k, v in aws_sagemaker_user_profile.users : k => v.arn }
}
