# =============================================================================
# NAT Gateway Module
# =============================================================================
# Standalone NAT Gateway for private subnet internet access.
# Works with both new VPC (create_vpc=true) and existing VPC (create_vpc=false).
# =============================================================================

resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = var.subnet_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-nat"
    }
  )
}

# Add route to NAT Gateway in private route tables
resource "aws_route" "nat" {
  count                  = var.create_nat_gateway ? length(var.private_route_table_ids) : 0
  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}
