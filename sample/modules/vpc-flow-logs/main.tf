# =============================================================================
# VPC Flow Logs Module
# =============================================================================
# Creates VPC Flow Logs for network traffic monitoring (Landing Zone compliance)
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_flow_log" "this" {
  vpc_id                   = var.vpc_id
  traffic_type             = var.traffic_type
  log_destination_type     = var.log_destination_type
  log_destination          = var.log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : aws_s3_bucket.flow_logs[0].arn
  iam_role_arn             = var.log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null
  max_aggregation_interval = var.max_aggregation_interval

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-vpc-flow-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Log Group destination
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.log_destination_type == "cloud-watch-logs" ? 1 : 0
  name              = "/aws/vpc/flow-logs/${var.name_prefix}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-vpc-flow-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM role for VPC Flow Logs to write to CloudWatch
resource "aws_iam_role" "flow_logs" {
  count                = var.log_destination_type == "cloud-watch-logs" ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-vpc-flow-logs-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.log_destination_type == "cloud-watch-logs" ? 1 : 0
  name  = "vpc-flow-logs-cloudwatch"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

# S3 bucket destination (alternative)
resource "aws_s3_bucket" "flow_logs" {
  count         = var.log_destination_type == "s3" ? 1 : 0
  bucket        = "${var.name_prefix}-${var.environment}-vpc-flow-logs-${data.aws_region.current.id}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-vpc-flow-logs"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count                   = var.log_destination_type == "s3" ? 1 : 0
  bucket                  = aws_s3_bucket.flow_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count  = var.log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count  = var.log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"
    filter {}

    transition {
      days          = var.log_archive_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expiration_days
    }
  }
}
