output "database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.this.name
}

output "database_arn" {
  description = "Glue catalog database ARN"
  value       = aws_glue_catalog_database.this.arn
}

output "crawler_name" {
  description = "Glue crawler name"
  value       = length(aws_glue_crawler.this) > 0 ? aws_glue_crawler.this[0].name : null
}

output "crawler_arn" {
  description = "Glue crawler ARN"
  value       = length(aws_glue_crawler.this) > 0 ? aws_glue_crawler.this[0].arn : null
}

output "job_name" {
  description = "Glue ETL job name"
  value       = var.create_etl_job ? aws_glue_job.this[0].name : null
}

output "job_arn" {
  description = "Glue ETL job ARN"
  value       = var.create_etl_job ? aws_glue_job.this[0].arn : null
}

output "connection_name" {
  description = "Glue connection name"
  value       = var.create_connection ? aws_glue_connection.this[0].name : null
}

output "glue_role_arn" {
  description = "IAM role ARN used by Glue"
  value       = var.glue_role_arn != null ? var.glue_role_arn : (length(aws_iam_role.glue) > 0 ? aws_iam_role.glue[0].arn : null)
}
