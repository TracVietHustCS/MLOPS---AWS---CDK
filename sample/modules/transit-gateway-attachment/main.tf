# =============================================================================
# Transit Gateway Attachment Module
# =============================================================================
# Attaches VPC to existing Transit Gateway for cross-VPC/on-premises connectivity
# =============================================================================

# -----------------------------------------------------------------------------
# Transit Gateway VPC Attachment
# -----------------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  dns_support                                     = var.dns_support ? "enable" : "disable"
  ipv6_support                                    = var.ipv6_support ? "enable" : "disable"
  appliance_mode_support                          = var.appliance_mode_support ? "enable" : "disable"
  transit_gateway_default_route_table_association = var.default_route_table_association
  transit_gateway_default_route_table_propagation = var.default_route_table_propagation

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-tgw-attachment"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Route to Transit Gateway (for private subnets)
# -----------------------------------------------------------------------------
resource "aws_route" "to_transit_gateway" {
  for_each = var.create_routes ? toset(var.route_table_ids) : []

  route_table_id         = each.value
  destination_cidr_block = var.destination_cidr_block
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}
