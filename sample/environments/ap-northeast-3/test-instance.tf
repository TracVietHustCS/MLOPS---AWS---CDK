# =============================================================================
# EC2 Test Instance
# =============================================================================
# Test instance to verify VPC endpoints using nslookup
# Connect via SSM Session Manager, then: cat /home/ec2-user/vpc-endpoint-results.txt
# =============================================================================

module "ec2_test" {
  source = "../../modules/ec2-test"
  count  = var.deploy_test_instance ? 1 : 0

  name_prefix          = var.name_prefix
  environment          = var.environment
  vpc_id               = local.vpc_id
  vpc_cidr             = local.vpc_cidr_block
  subnet_id            = local.private_subnet_ids[0]
  instance_type        = var.test_instance_type
  permissions_boundary = local.permissions_boundary

  tags = var.tags
}
