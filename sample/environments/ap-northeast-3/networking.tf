# =============================================================================
# Networking Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Endpoints
# -----------------------------------------------------------------------------
module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"
  count  = var.create_vpc_endpoints ? 1 : 0

  name_prefix     = var.name_prefix
  environment     = var.environment
  vpc_id          = local.vpc_id
  aws_region      = var.aws_region
  subnet_ids      = local.private_subnet_ids
  route_table_ids = local.route_table_ids

  security_group_ids = [module.vpc_endpoints_sg.security_group_id]

  create_s3_gateway         = var.create_s3_gateway
  create_s3_interface       = var.create_s3_interface
  sagemaker_endpoint        = var.create_sagemaker_endpoint
  ecr_endpoint              = var.create_ecr_endpoint
  ecr_dkr_endpoint          = var.create_ecr_docker_endpoint
  cloudwatch_endpoint       = var.create_cloudwatch_endpoint
  secretsmanager_endpoint   = var.create_secrets_manager_endpoint
  api_gateway_endpoint      = var.create_api_gateway_endpoint
  lambda_endpoint           = var.create_lambda_endpoint
  ssm_endpoint              = var.create_ssm_endpoint

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Transit Gateway Attachment
# -----------------------------------------------------------------------------
module "transit_gateway_attachment" {
  source = "../../modules/transit-gateway-attachment"
  count  = var.deploy_transit_gateway_attachment && var.transit_gateway_id != null ? 1 : 0

  name_prefix        = var.name_prefix
  environment        = var.environment
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = local.vpc_id
  subnet_ids         = local.private_subnet_ids

  # Route configuration
  create_routes          = true
  route_table_ids        = local.route_table_ids
  destination_cidr_block = var.tgw_destination_cidr

  tags = var.tags
}
