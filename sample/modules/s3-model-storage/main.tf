resource "random_id" "suffix" {
  byte_length = 4
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "model_bucket" {
  bucket        = "${var.name_prefix}-${var.environment}-models-${data.aws_region.current.id}-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-models"
      Environment = var.environment
      Purpose     = "ML Model Storage"
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "model_bucket" {
  bucket = aws_s3_bucket.model_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "model_bucket" {
  bucket = aws_s3_bucket.model_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model_bucket" {
  bucket = aws_s3_bucket.model_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
    blocked_encryption_types = ["NONE"]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "model_bucket" {
  count  = var.enable_lifecycle_policy ? 1 : 0
  bucket = aws_s3_bucket.model_bucket.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "model_bucket" {
  count  = length(var.sagemaker_execution_role_arns) > 0 ? 1 : 0
  bucket = aws_s3_bucket.model_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSageMakerAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.sagemaker_execution_role_arns
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.model_bucket.arn,
          "${aws_s3_bucket.model_bucket.arn}/*"
        ]
      }
    ]
  })
}
