# Instance outputs
output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.rds.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.rds.arn
}

output "db_instance_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.rds.resource_id
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.rds.endpoint
}

output "db_instance_address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.rds.address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.rds.port
}

# Database outputs
output "database_name" {
  description = "Name of the default database"
  value       = aws_db_instance.rds.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.rds.username
  sensitive   = true
}

# Subnet group output
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.rds.name
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.rds.arn
}
