module "sagemaker_role" {
  source = "../../modules/iam-role"

  role_name            = "${var.name_prefix}-${var.environment}-sagemaker-${var.aws_region}"
  permissions_boundary = local.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })

  inline_policies = {
    ecr_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }]
    })

    cloudwatch_custom = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }]
    })

    s3_model_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket",
            "s3:GetBucketAcl",
            "s3:PutObjectAcl"
          ]
          Resource = [
            module.s3_model_storage.bucket_arn,
            "${module.s3_model_storage.bucket_arn}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::sagemaker-${var.aws_region}-${data.aws_caller_identity.current.account_id}/*"
        }
      ]
    })

    logs = jsonencode({
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
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/*"
      }]
    })

    vpc_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      }]
    })
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-sagemaker-role"
    }
  )
}

# Wait for IAM role to propagate across AWS services
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [module.sagemaker_role]

  create_duration = "1m"
}

module "scheduler_role" {
  source = "../../modules/iam-role"

  role_name            = "${var.name_prefix}-${var.environment}-scheduler-${var.aws_region}"
  permissions_boundary = local.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  inline_policies = {
    lambda_invoke = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.name_prefix}-${var.environment}-*"
      }]
    })

    cloudwatch = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }]
    })

    s3 = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          module.s3_model_storage.bucket_arn,
          "${module.s3_model_storage.bucket_arn}/*"
        ]
      }]
    })

    sagemaker = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sagemaker:AddTags",
            "sagemaker:DescribeEndpoint",
            "sagemaker:CreateEndpoint",
            "sagemaker:DeleteEndpoint"
          ]
          Resource = [
            "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/${var.name_prefix}-${var.environment}-*",
            "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint-config/${var.name_prefix}-${var.environment}-*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "sagemaker:ListTags",
            "sagemaker:DescribeEndpoint",
            "sagemaker:DescribeEndpointConfig",
            "sagemaker:ListEndpoints",
            "sagemaker:ListEndpointConfigs",
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "sagemaker:DescribeEndpointConfig"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "application-autoscaling:RegisterScalableTarget",
            "application-autoscaling:DeregisterScalableTarget",
            "application-autoscaling:DescribeScalableTargets",
            "application-autoscaling:DescribeScalingPolicies",
            "application-autoscaling:PutScalingPolicy",
            "application-autoscaling:DeleteScalingPolicy"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DescribeAlarms"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "sagemaker:UpdateEndpointWeightsAndCapacities"
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-scheduler-role"
    }
  )
}
