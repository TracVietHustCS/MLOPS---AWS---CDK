
module "s3_model_storage" {
  source = "../../modules/s3-model-storage"

  name_prefix                        = var.name_prefix
  environment                        = var.environment
  enable_versioning                  = true
  enable_lifecycle_policy            = true
  noncurrent_version_expiration_days = 30
  tags                               = var.tags
}

# -----------------------------------------------------------------------------
# RRTH-MH-BDS Data Bucket
# -----------------------------------------------------------------------------
module "s3_rrth_mh_bds" {
  source = "../../modules/s3-data-bucket"

  bucket_name       = var.data_bucket_name
  environment       = var.environment
  enable_versioning = true
  force_destroy     = var.environment != "prod"
  kms_key_arn       = var.deploy_kms ? module.kms_key_s3[0].key_arn : null
  vpc_endpoint_id            = var.create_vpc_endpoints && length(module.vpc_endpoints) > 0 ? module.vpc_endpoints[0].s3_gateway_endpoint_id : null
  enable_vpc_endpoint_policy = var.create_vpc_endpoints
  tags              = var.tags
}
