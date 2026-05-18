output "secret_ids" {
  description = "Map of secret IDs"
  value = {
    for key, secret in aws_secretsmanager_secret.secret : key => secret.id
  }
}

output "secret_arns" {
  description = "Map of secret ARNs"
  value = {
    for key, secret in aws_secretsmanager_secret.secret : key => secret.arn
  }
}

output "secret_names" {
  description = "Map of secret names"
  value = {
    for key, secret in aws_secretsmanager_secret.secret : key => secret.name
  }
}

output "secret_version_ids" {
  description = "Map of secret version IDs"
  value = {
    for key, version in aws_secretsmanager_secret_version.secret_version : key => version.version_id
  }
}
