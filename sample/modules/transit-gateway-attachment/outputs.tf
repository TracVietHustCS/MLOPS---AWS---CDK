# =============================================================================
# Transit Gateway Attachment Outputs
# =============================================================================

output "attachment_id" {
  description = "Transit Gateway Attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "vpc_owner_id" {
  description = "VPC owner account ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.vpc_owner_id
}
