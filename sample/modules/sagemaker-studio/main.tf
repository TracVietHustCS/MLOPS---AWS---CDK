# =============================================================================
# SageMaker Studio Domain Module
# =============================================================================
# Creates SageMaker Studio Domain with user profiles for data scientists
# =============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# SageMaker Studio Domain
# -----------------------------------------------------------------------------
resource "aws_sagemaker_domain" "this" {
  domain_name             = "${var.name_prefix}-${var.environment}-studio"
  auth_mode               = var.auth_mode
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  app_network_access_type = var.app_network_access_type

  default_user_settings {
    execution_role = var.execution_role_arn

    security_groups = var.security_group_ids

    sharing_settings {
      notebook_output_option = var.notebook_output_option
      s3_output_path         = var.s3_output_path != null ? var.s3_output_path : null
    }

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type       = var.jupyter_server_instance_type
        sagemaker_image_arn = var.jupyter_server_image_arn
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type       = var.default_instance_type
        sagemaker_image_arn = var.kernel_gateway_image_arn
      }
    }
  }

  default_space_settings {
    execution_role  = var.execution_role_arn
    security_groups = var.security_group_ids
  }

  domain_settings {
    security_group_ids = var.security_group_ids
  }

  retention_policy {
    home_efs_file_system = var.retain_efs ? "Retain" : "Delete"
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-studio"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# SageMaker Studio User Profiles
# -----------------------------------------------------------------------------
resource "aws_sagemaker_user_profile" "users" {
  for_each = { for user in var.user_profiles : user.name => user }

  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = each.value.name

  user_settings {
    execution_role  = each.value.execution_role_arn != null ? each.value.execution_role_arn : var.execution_role_arn
    security_groups = var.security_group_ids

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = each.value.jupyter_instance_type != null ? each.value.jupyter_instance_type : var.jupyter_server_instance_type
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = each.value.notebook_instance_type != null ? each.value.notebook_instance_type : var.default_instance_type
      }
    }
  }

  tags = merge(
    {
      Name        = each.value.name
      Environment = var.environment
    },
    var.tags
  )
}
