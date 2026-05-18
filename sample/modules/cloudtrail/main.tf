# =============================================================================
# CloudTrail Module
# =============================================================================
# Creates CloudTrail for audit logging (Landing Zone compliance)
# Logs to CloudWatch Logs + S3 (S3 is required by AWS)
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 bucket for CloudTrail (required by AWS)
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.name_prefix}-${var.environment}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-cloudtrail"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    transition {
      days          = var.log_archive_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = var.kms_key_arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-trail"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.name_prefix}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-cloudtrail-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM role for CloudTrail to write to CloudWatch
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name                 = "${var.name_prefix}-${var.environment}-cloudtrail-cw-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
    }]
  })
}
