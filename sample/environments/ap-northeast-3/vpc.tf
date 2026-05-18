# =============================================================================
# VPC Configuration
# =============================================================================
# Option 1: Create new VPC (create_vpc = true)
# Option 2: Use existing VPC (create_vpc = false, provide vpc_id)
# =============================================================================

module "vpc" {
  count  = var.create_vpc ? 1 : 0
  source = "../../modules/vpc"

  name_prefix = var.name_prefix
  environment = var.environment

  cidr_block            = var.vpc_cidr_block
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr

  create_nat_gateway = false  # NAT handled by standalone nat-gateway module

  tags = var.tags
}

# Locals to handle both new and existing VPC
locals {
  vpc_id             = var.create_vpc ? module.vpc[0].vpc_id : var.vpc_id
  vpc_cidr_block     = var.create_vpc ? module.vpc[0].vpc_cidr_block : data.aws_vpc.main[0].cidr_block
  subnet_ids         = var.create_vpc ? module.vpc[0].private_subnet_ids : var.subnet_ids
  private_subnet_ids = var.create_vpc ? module.vpc[0].private_subnet_ids : var.subnet_ids

  # Public subnet for NAT Gateway
  public_subnet_id = var.create_vpc ? module.vpc[0].public_subnet_ids[0] : var.public_subnet_id

  # Route table IDs for VPC endpoints and NAT
  route_table_ids = var.create_vpc ? module.vpc[0].private_route_table_ids : distinct([
    for rt in data.aws_route_table.sagemaker_route_tables : rt.id
  ])

  # Egress CIDR blocks - priority: custom > VPC CIDR (if restricted) > 0.0.0.0/0
  egress_cidr_blocks = length(var.egress_cidr_blocks) > 0 ? var.egress_cidr_blocks : (
    var.restrict_egress_to_vpc ? [local.vpc_cidr_block] : ["0.0.0.0/0"]
  )
}

# =============================================================================
# NAT Gateway (standalone module, works with both new and existing VPC)
# =============================================================================
module "nat_gateway" {
  count  = var.create_nat_gateway ? 1 : 0
  source = "../../modules/nat-gateway"

  name_prefix = var.name_prefix
  environment = var.environment

  create_nat_gateway      = true
  subnet_id               = local.public_subnet_id
  private_route_table_ids = local.route_table_ids

  tags = var.tags
}
