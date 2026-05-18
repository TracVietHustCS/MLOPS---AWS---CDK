# Secrets Manager Module
# Creates AWS Secrets Manager secrets with optional random password generation

locals {
  # Filter secrets that need random password generation
  secrets_with_random_password = {
    for key, secret in var.secrets : key => secret
    if lookup(secret, "generate_random_password", false)
  }
}

# Generate random passwords for secrets that require them
resource "random_password" "secret_password" {
  for_each = local.secrets_with_random_password

  length  = lookup(each.value, "password_length", 32)
  special = false  # RDS does not allow: / @ " and space - disable special chars entirely
  upper   = true
  lower   = true
  numeric = true
}

# Create secrets
resource "aws_secretsmanager_secret" "secret" {
  for_each = var.secrets

  name        = "${var.name_prefix}-${var.environment}-${each.value.name}"
  description = lookup(each.value, "description", "Managed by Terraform")

  kms_key_id                     = var.kms_key_id
  recovery_window_in_days        = var.recovery_window_in_days
  force_overwrite_replica_secret = lookup(each.value, "force_overwrite_replica_secret", false)

  tags = merge(
    {
      Name        = "${var.name_prefix}-${each.value.name}"
      Environment = var.environment
    },
    var.tags
  )
}

# Set secret values
resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = var.secrets

  secret_id = aws_secretsmanager_secret.secret[each.key].id

  # Use generated password if generate_random_password is true, otherwise use provided secret_string
  secret_string = lookup(each.value, "generate_random_password", false) ? (
    random_password.secret_password[each.key].result
  ) : lookup(each.value, "secret_string", null)
}

# Secret rotation configuration (Landing Zone compliance)
resource "aws_secretsmanager_secret_rotation" "rotation" {
  for_each = var.enable_rotation && var.rotation_lambda_arn != null ? var.secrets : {}

  secret_id           = aws_secretsmanager_secret.secret[each.key].id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  depends_on = [aws_secretsmanager_secret_version.secret_version]
}
