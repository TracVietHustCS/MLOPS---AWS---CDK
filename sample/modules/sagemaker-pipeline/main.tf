data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  pipeline_name   = "${var.name_prefix}-${var.environment}-${var.pipeline_name}"
  use_s3_location = var.pipeline_definition_s3_bucket != null && var.pipeline_definition_s3_key != null
}

resource "aws_sagemaker_pipeline" "pipeline" {
  pipeline_name         = local.pipeline_name
  pipeline_display_name = coalesce(var.pipeline_display_name, local.pipeline_name)
  role_arn              = var.role_arn

  # Pipeline definition from S3
  dynamic "pipeline_definition_s3_location" {
    for_each = local.use_s3_location ? [1] : []
    content {
      bucket     = var.pipeline_definition_s3_bucket
      object_key = var.pipeline_definition_s3_key
    }
  }

  # Pipeline definition inline (when not using S3)
  pipeline_definition = local.use_s3_location ? null : var.pipeline_definition_body

  dynamic "parallelism_configuration" {
    for_each = var.max_parallel_execution_steps != null ? [1] : []
    content {
      max_parallel_execution_steps = var.max_parallel_execution_steps
    }
  }

  tags = merge(
    {
      Name        = local.pipeline_name
      Environment = var.environment
    },
    var.tags
  )
}
