output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.create_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "nat_eip_public_ip" {
  description = "NAT Gateway Elastic IP"
  value       = var.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}
