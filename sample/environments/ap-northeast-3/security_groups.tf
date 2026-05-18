# =============================================================================
# Security Groups Configuration
# =============================================================================
# Egress rules use local.egress_cidr_blocks which is controlled by:
# - var.restrict_egress_to_vpc (default: true) - restricts to VPC CIDR
# - var.egress_cidr_blocks - custom CIDR blocks (overrides above)
# =============================================================================

module "alb_sg" {
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "alb"
  description   = "Security group for Application Load Balancer"

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.alb_ingress_cidr_blocks
      description = "HTTPS"
    }
  }

  egress_rules = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = local.egress_cidr_blocks
      description = "Allow outbound to ${var.restrict_egress_to_vpc ? "VPC" : "all"}"
    }
  }

  tags = var.tags
}

module "eic_sg" {
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "instance-endpoint"
  description   = "Security group for EC2 Instance Connect Endpoint"

  egress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "SSH to VPC instances"
    }
  }

  tags = var.tags
}

module "sagemaker_sg" {
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "sagemaker"
  description   = "Security group for SageMaker endpoints"

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "HTTPS from VPC"
    }
  }

  # Note: When restrict_egress_to_vpc = true, egress is limited to VPC CIDR
  # S3 access via Gateway endpoint uses route tables, not security groups
  egress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.egress_cidr_blocks
      description = "HTTPS to AWS services"
    }
  }

  tags = var.tags
}

module "vpc_endpoints_sg" {
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "vpc-endpoints"
  description   = "Security group for VPC endpoints"

  ingress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "HTTPS from VPC"
    }
  }

  # VPC endpoints typically don't need egress rules
  egress_rules = {}

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Lambda Security Group (for VPC-enabled Lambda functions)
# -----------------------------------------------------------------------------
module "lambda_sg" {
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "lambda"
  description   = "Security group for Lambda functions in VPC"

  # Lambda typically doesn't need ingress (it initiates connections)
  ingress_rules = {}

  egress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "HTTPS to VPC endpoints"
    }
    postgres = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "PostgreSQL to RDS"
    }
    # S3 access via Gateway endpoint doesn't need SG rule
    # Gateway endpoints use route tables, not security groups
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Glue Security Group (for Glue connections to data sources)
# -----------------------------------------------------------------------------
module "glue_sg" {
  source = "../../modules/security-group"

  name_prefix   = var.name_prefix
  environment   = var.environment
  vpc_id        = local.vpc_id
  resource_name = "glue"
  description   = "Security group for AWS Glue ETL jobs"

  # Base ingress rules (self-referencing added separately below)
  ingress_rules = {}

  egress_rules = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.egress_cidr_blocks
      description = "HTTPS for AWS services"
    }
    postgres = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "PostgreSQL to RDS"
    }
  }

  tags = var.tags
}

# Glue self-referencing rules (must be added after SG is created)
resource "aws_security_group_rule" "glue_self_ingress" {
  security_group_id        = module.glue_sg.security_group_id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.glue_sg.security_group_id
  description              = "Allow Glue workers to communicate (self-reference)"
}

resource "aws_security_group_rule" "glue_self_egress" {
  security_group_id        = module.glue_sg.security_group_id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.glue_sg.security_group_id
  description              = "Allow Glue workers to communicate (self-reference)"
}
