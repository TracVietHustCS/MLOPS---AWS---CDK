output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.model_bucket.id
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.model_bucket.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.model_bucket.arn
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.model_bucket.region
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.model_bucket.bucket_domain_name
}