# =============================================================================
# AWS Config Module
# =============================================================================
# Configuration recording and compliance monitoring
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# S3 Bucket for Config Logs
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "config" {
  count         = var.create_s3_bucket ? 1 : 0
  bucket        = "${var.name_prefix}-${var.environment}-config-${data.aws_region.current.id}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-config-bucket"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "config" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    id     = "config-logs-lifecycle"
    status = "Enabled"

    transition {
      days          = var.s3_log_archive_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.s3_log_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config[0].arn}/${var.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM Role for Config
# -----------------------------------------------------------------------------
resource "aws_iam_role" "config" {
  name                 = "${var.name_prefix}-${var.environment}-config-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  name = "config-s3-delivery"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:PutObjectAcl"]
        Resource = "${var.create_s3_bucket ? aws_s3_bucket.config[0].arn : "arn:aws:s3:::${var.s3_bucket_name}"}/${var.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringLike = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetBucketAcl"]
        Resource = var.create_s3_bucket ? aws_s3_bucket.config[0].arn : "arn:aws:s3:::${var.s3_bucket_name}"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Config Recorder
# -----------------------------------------------------------------------------
resource "aws_config_configuration_recorder" "this" {
  name     = "${var.name_prefix}-${var.environment}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = var.recording_all_resources
    include_global_resource_types = var.include_global_resources
    resource_types                = var.recording_all_resources ? null : var.recording_resource_types
  }

  recording_mode {
    recording_frequency = "CONTINUOUS"
  }
}

# -----------------------------------------------------------------------------
# Delivery Channel
# -----------------------------------------------------------------------------
resource "aws_config_delivery_channel" "this" {
  name           = "${var.name_prefix}-${var.environment}-delivery"
  s3_bucket_name = var.create_s3_bucket ? aws_s3_bucket.config[0].id : var.s3_bucket_name
  s3_key_prefix  = var.s3_key_prefix
  sns_topic_arn  = var.sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.this]
}

# -----------------------------------------------------------------------------
# Config Recorder Status (Enable)
# -----------------------------------------------------------------------------
resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

# -----------------------------------------------------------------------------
# AWS Managed Config Rules
# -----------------------------------------------------------------------------
resource "aws_config_config_rule" "managed" {
  for_each = var.enable_managed_rules ? { for rule in var.managed_rules : rule.name => rule } : {}

  name = "${var.name_prefix}-${each.value.name}"

  source {
    owner             = "AWS"
    source_identifier = each.value.identifier
  }

  input_parameters            = length(each.value.input_parameters) > 0 ? jsonencode(each.value.input_parameters) : null
  maximum_execution_frequency = each.value.maximum_execution_frequency

  depends_on = [aws_config_configuration_recorder.this]

  tags = var.tags
}
