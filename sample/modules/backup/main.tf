# =============================================================================
# AWS Backup Module
# =============================================================================
# Automated backup for RDS, S3, and other resources
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Backup Vault
# -----------------------------------------------------------------------------
resource "aws_backup_vault" "this" {
  name        = "${var.name_prefix}-${var.environment}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-backup-vault"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Backup Plan
# -----------------------------------------------------------------------------
resource "aws_backup_plan" "this" {
  name = "${var.name_prefix}-${var.environment}-backup-plan"

  # Daily backup rule
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.daily_backup_schedule

    lifecycle {
      delete_after = var.daily_backup_retention_days
    }

    # Cross-region copy (only when a separate vault is provided)
    dynamic "copy_action" {
      for_each = var.copy_to_vault_arn != null ? [1] : []
      content {
        lifecycle {
          delete_after = var.daily_backup_retention_days
        }
        destination_vault_arn = var.copy_to_vault_arn
      }
    }
  }

  # Weekly backup rule (optional)
  dynamic "rule" {
    for_each = var.enable_weekly_backup ? [1] : []
    content {
      rule_name         = "weekly-backup"
      target_vault_name = aws_backup_vault.this.name
      schedule          = var.weekly_backup_schedule

      lifecycle {
        delete_after = var.weekly_backup_retention_days
      }
    }
  }

  # Monthly backup rule (optional)
  dynamic "rule" {
    for_each = var.enable_monthly_backup ? [1] : []
    content {
      rule_name         = "monthly-backup"
      target_vault_name = aws_backup_vault.this.name
      schedule          = var.monthly_backup_schedule

      lifecycle {
        delete_after       = var.monthly_backup_retention_days
        cold_storage_after = var.monthly_backup_cold_storage_days
      }
    }
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-backup-plan"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Backup Selection (Resources to backup)
# -----------------------------------------------------------------------------
resource "aws_backup_selection" "this" {
  name         = "${var.name_prefix}-${var.environment}-backup-selection"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = var.backup_role_arn != null ? var.backup_role_arn : aws_iam_role.backup[0].arn

  # Select by resource ARNs
  dynamic "selection_tag" {
    for_each = var.backup_selection_tags
    content {
      type  = "STRINGEQUALS"
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }

  # Direct resource ARNs
  resources = var.backup_resource_arns
}

# -----------------------------------------------------------------------------
# IAM Role for AWS Backup
# -----------------------------------------------------------------------------
resource "aws_iam_role" "backup" {
  count                = var.backup_role_arn == null ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-backup-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.backup_role_arn == null ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count      = var.backup_role_arn == null ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Additional policy for RDS backup
resource "aws_iam_role_policy" "backup_rds" {
  count = var.backup_role_arn == null ? 1 : 0
  name  = "backup-rds-policy"
  role  = aws_iam_role.backup[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:AddTagsToResource",
          "rds:ListTagsForResource",
          "rds:DescribeDBSnapshots",
          "rds:CreateDBSnapshot",
          "rds:CopyDBSnapshot",
          "rds:DescribeDBInstances",
          "rds:CreateDBClusterSnapshot",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshots",
          "rds:CopyDBClusterSnapshot"
        ]
        Resource = "*"
      }
    ]
  })
}
