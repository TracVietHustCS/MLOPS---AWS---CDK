output "vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.this.arn
}

output "vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.this.name
}

output "plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.this.arn
}

output "plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.this.id
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = var.backup_role_arn != null ? var.backup_role_arn : aws_iam_role.backup[0].arn
}
