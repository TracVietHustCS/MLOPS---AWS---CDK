locals {
  model_package_group_name = "${var.name_prefix}-${var.environment}-${var.model_package_group_name}"
}

resource "aws_sagemaker_model_package_group" "model_package_group" {
  model_package_group_name        = local.model_package_group_name
  model_package_group_description = var.model_package_group_description

  tags = merge(
    {
      Name        = local.model_package_group_name
      Environment = var.environment
    },
    var.tags
  )
}
