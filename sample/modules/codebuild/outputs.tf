output "project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.this.name
}

output "project_arn" {
  description = "CodeBuild project ARN"
  value       = aws_codebuild_project.this.arn
}

output "project_id" {
  description = "CodeBuild project ID"
  value       = aws_codebuild_project.this.id
}

output "service_role_arn" {
  description = "IAM role ARN used by CodeBuild"
  value       = var.service_role_arn != null ? var.service_role_arn : aws_iam_role.codebuild[0].arn
}
