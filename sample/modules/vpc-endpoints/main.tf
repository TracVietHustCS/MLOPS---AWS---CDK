# -----------------------------------------------------------------------------
# S3 Gateway Endpoint (required for S3 Interface with private DNS)
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count             = var.create_s3_gateway || var.create_s3_interface ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-s3-gateway-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# S3 Interface Endpoint (private DNS - requires Gateway endpoint first)
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3_interface" {
  count               = var.create_s3_interface ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-s3-interface-endpoint"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_vpc_endpoint.s3]
}

resource "aws_vpc_endpoint" "sagemaker_featurestore" {
  count               = var.sagemaker_featurestore_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.featurestore-runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-sagemaker-featurestore-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "sagemaker_api" {
  count               = var.sagemaker_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-sagemaker-api-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "sagemaker_runtime" {
  count               = var.sagemaker_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-sagemaker-runtime-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.ecr_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-ecr-api-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.ecr_dkr_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-ecr-dkr-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "logs" {
  count               = var.cloudwatch_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-logs-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "secretsmanager" {
  count               = var.secretsmanager_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-secretsmanager-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# API Gateway Private Endpoint
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "execute_api" {
  count               = var.api_gateway_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-execute-api-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Lambda Private Endpoint
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "lambda" {
  count               = var.lambda_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-lambda-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}


# -----------------------------------------------------------------------------
# SSM Endpoints (for Session Manager)
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "ssm" {
  count               = var.ssm_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-ssm-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = var.ssm_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-ssmmessages-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.ssm_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-ec2messages-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}


# -----------------------------------------------------------------------------
# Cognito User Pool Private Endpoint
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "cognito_idp" {
  count               = var.cognito_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.cognito-idp"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-cognito-idp-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}
