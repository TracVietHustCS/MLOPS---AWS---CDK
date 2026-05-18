resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-${var.environment}-${var.resource_name}-sg"
  description = var.description
  vpc_id      = var.vpc_id

  timeouts {
    delete = "20m"
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.resource_name}-sg"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.ingress_rules

  security_group_id        = aws_security_group.this.id
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description              = lookup(each.value, "description", null)
}

resource "aws_security_group_rule" "egress" {
  for_each = var.egress_rules

  security_group_id        = aws_security_group.this.id
  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description              = lookup(each.value, "description", null)
}