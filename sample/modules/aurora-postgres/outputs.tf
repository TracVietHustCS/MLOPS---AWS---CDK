# Cluster outputs
output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.aurora.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.aurora.arn
}

output "cluster_resource_id" {
  description = "Aurora cluster resource ID"
  value       = aws_rds_cluster.aurora.cluster_resource_id
}

output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = aws_rds_cluster.aurora.port
}

# Database outputs
output "database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.aurora.database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.aurora.master_username
  sensitive   = true
}

# Instance outputs
output "instance_ids" {
  description = "List of Aurora instance identifiers"
  value       = aws_rds_cluster_instance.aurora[*].id
}

output "instance_arns" {
  description = "List of Aurora instance ARNs"
  value       = aws_rds_cluster_instance.aurora[*].arn
}

output "instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = aws_rds_cluster_instance.aurora[*].endpoint
}

# Subnet group output
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.aurora.name
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.aurora.arn
}

# Compatibility outputs (match RDS module interface)
output "db_instance_endpoint" {
  description = "Aurora cluster endpoint (for RDS compatibility)"
  value       = aws_rds_cluster.aurora.endpoint
}

output "db_instance_address" {
  description = "Aurora cluster endpoint without port (for RDS compatibility)"
  value       = split(":", aws_rds_cluster.aurora.endpoint)[0]
}

output "db_instance_arn" {
  description = "Aurora cluster ARN (for RDS compatibility)"
  value       = aws_rds_cluster.aurora.arn
}

output "db_instance_port" {
  description = "Aurora cluster port (for RDS compatibility)"
  value       = aws_rds_cluster.aurora.port
}
