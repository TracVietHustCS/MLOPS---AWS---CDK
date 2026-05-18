# =============================================================================
# KMS Key Module
# =============================================================================
# Creates KMS keys for encryption of S3, RDS, ECR, Secrets Manager, etc.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  is_enabled              = true
  multi_region            = var.multi_region

  policy = var.key_policy != null ? var.key_policy : jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "EnableRootAccountAccess"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        }
      ],
      length(var.key_administrators) > 0 ? [
        {
          Sid    = "AllowKeyAdministration"
          Effect = "Allow"
          Principal = {
            AWS = var.key_administrators
          }
          Action = [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion"
          ]
          Resource = "*"
        }
      ] : [],
      length(var.key_users) > 0 ? [
        {
          Sid    = "AllowServiceUsage"
          Effect = "Allow"
          Principal = {
            AWS = var.key_users
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey",
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ]
          Resource = "*"
        }
      ] : [],
      length(var.allowed_services) > 0 ? [
        {
          Sid    = "AllowAWSServices"
          Effect = "Allow"
          Principal = {
            Service = var.allowed_services
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey",
            "kms:CreateGrant"
          ]
          Resource = "*"
        }
      ] : []
    )
  })

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.key_name}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-${var.environment}-${var.key_name}"
  target_key_id = aws_kms_key.this.key_id
}
