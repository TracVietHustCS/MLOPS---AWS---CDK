# S3 Data Bucket Module
# Creates S3 bucket with VPC endpoint policy support

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name        = var.bucket_name
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    blocked_encryption_types = ["NONE"]
  }
}

# VPC Endpoint policy - restrict access to VPC endpoint only
# resource "aws_s3_bucket_policy" "this" {
#   count  = var.enable_vpc_endpoint_policy ? 1 : 0
#   bucket = aws_s3_bucket.this.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AllowVPCEndpointAccess"
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket",
#           "s3:DeleteObject"
#         ]
#         Resource = [
#           aws_s3_bucket.this.arn,
#           "${aws_s3_bucket.this.arn}/*"
#         ]
#         Condition = {
#           StringEquals = {
#             "aws:sourceVpce" = var.vpc_endpoint_id
#           }
#         }
#       }
#     ]
#   })
# }
