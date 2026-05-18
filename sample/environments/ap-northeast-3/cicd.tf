# =============================================================================
# SageMaker CodeBuild Projects
# =============================================================================
# CodeBuild for deploying models to SageMaker endpoints
# Container build handled by team's existing CI/CD pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# CodeBuild - Model Deploy for SageMaker
# -----------------------------------------------------------------------------
module "sagemaker_codebuild_deploy" {
  count  = var.deploy_sagemaker_codebuild ? 1 : 0
  source = "../../modules/codebuild"

  name_prefix  = var.name_prefix
  environment  = var.environment
  project_name = "sagemaker-model-deploy"
  description  = "Deploy ML models to SageMaker endpoints"

  privileged_mode      = false
  compute_type         = "BUILD_GENERAL1_SMALL"
  build_image          = var.sagemaker_codebuild_image
  source_type          = "NO_SOURCE"
  artifacts_type       = "NO_ARTIFACTS"
  kms_key_arn          = var.deploy_kms ? module.kms_key_ecr[0].key_arn : null
  permissions_boundary = local.permissions_boundary

  enable_vpc         = false  # CodeBuild dùng internet mặc định

  environment_variables = [
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
    { name = "AWS_REGION", value = var.aws_region },
    { name = "ENVIRONMENT", value = var.environment },
    { name = "NAME_PREFIX", value = var.name_prefix }
  ]

  buildspec = <<-BUILDSPEC
    version: 0.2
    phases:
      build:
        commands:
          - echo Deploying model to SageMaker...
          - python scripts/deploy_model.py --environment $ENVIRONMENT --prefix $NAME_PREFIX --region $AWS_REGION
  BUILDSPEC

  s3_access_arns = [
    module.s3_model_storage.bucket_arn,
    "${module.s3_model_storage.bucket_arn}/*"
  ]

  tags = var.tags
}
