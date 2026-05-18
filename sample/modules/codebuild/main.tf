# =============================================================================
# CodeBuild Module
# =============================================================================
# Creates CodeBuild projects for building ML containers and running tests
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_codebuild_project" "this" {
  name          = "${var.name_prefix}-${var.environment}-${var.project_name}"
  description   = var.description
  build_timeout = var.build_timeout
  service_role  = var.service_role_arn != null ? var.service_role_arn : aws_iam_role.codebuild[0].arn

  artifacts {
    type = var.artifacts_type
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.build_image
    type                        = var.environment_type
    privileged_mode             = var.privileged_mode
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = lookup(environment_variable.value, "type", "PLAINTEXT")
      }
    }
  }

  source {
    type      = var.source_type
    buildspec = var.buildspec
    location  = var.source_location
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      vpc_id             = var.vpc_id
      subnets            = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.name_prefix}-${var.environment}-${var.project_name}"
      stream_name = ""
    }

    dynamic "s3_logs" {
      for_each = var.s3_log_bucket != null ? [1] : []
      content {
        status   = "ENABLED"
        location = "${var.s3_log_bucket}/codebuild-logs"
      }
    }
  }

  encryption_key = var.kms_key_arn

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.project_name}"
      Environment = var.environment
    },
    var.tags
  )

  # Ignore buildspec drift caused by Windows CRLF vs AWS LF line endings
  lifecycle {
    ignore_changes = [source]
  }
}

# Default IAM role for CodeBuild (created only if service_role_arn is not provided)
resource "aws_iam_role" "codebuild" {
  count                = var.service_role_arn == null ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-codebuild-${var.project_name}"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild" {
  count = var.service_role_arn == null ? 1 : 0
  name  = "codebuild-policy"
  role  = aws_iam_role.codebuild[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = var.s3_access_arns
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:UpdateEndpoint",
          "sagemaker:DescribeEndpoint",
          "sagemaker:CreateModelPackage",
          "sagemaker:DescribeModelPackage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/acb/*"
      }
    ]
  })
}

# VPC access policy (only if VPC config is provided)
resource "aws_iam_role_policy" "codebuild_vpc" {
  count = var.service_role_arn == null && var.enable_vpc ? 1 : 0
  name  = "codebuild-vpc-policy"
  role  = aws_iam_role.codebuild[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeVpcs",
        "ec2:CreateNetworkInterfacePermission"
      ]
      Resource = "*"
    }]
  })
}
