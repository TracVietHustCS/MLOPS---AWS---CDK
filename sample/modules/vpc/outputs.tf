output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private Route Table IDs"
  value       = [aws_route_table.private_1.id, aws_route_table.private_2.id]
}
