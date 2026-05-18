data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  feature_group_name = "${var.name_prefix}-${var.environment}-${var.feature_group_name}"
}

resource "aws_sagemaker_feature_group" "feature_group" {
  feature_group_name             = local.feature_group_name
  record_identifier_feature_name = var.record_identifier_name
  event_time_feature_name        = var.event_time_name
  role_arn                       = var.role_arn

  # Record identifier feature definition
  feature_definition {
    feature_name = var.record_identifier_name
    feature_type = "String"
  }

  # Event time feature definition
  feature_definition {
    feature_name = var.event_time_name
    feature_type = "Fractional"
  }

  # Dynamic feature definitions
  dynamic "feature_definition" {
    for_each = var.feature_definitions
    content {
      feature_name = feature_definition.value.feature_name
      feature_type = feature_definition.value.feature_type
    }
  }

  # Online store configuration
  dynamic "online_store_config" {
    for_each = var.enable_online_store ? [1] : []
    content {
      enable_online_store = true

      dynamic "security_config" {
        for_each = var.online_store_kms_key_id != null ? [1] : []
        content {
          kms_key_id = var.online_store_kms_key_id
        }
      }
    }
  }

  # Offline store configuration
  dynamic "offline_store_config" {
    for_each = var.enable_offline_store ? [1] : []
    content {
      s3_storage_config {
        s3_uri                 = var.offline_store_s3_uri
        kms_key_id             = var.offline_store_kms_key_id
      }

      disable_glue_table_creation = var.disable_glue_table_creation
      table_format                = var.offline_store_table_format

      dynamic "data_catalog_config" {
        for_each = var.glue_catalog_config != null ? [var.glue_catalog_config] : []
        content {
          catalog    = data_catalog_config.value.catalog
          database   = data_catalog_config.value.database
          table_name = data_catalog_config.value.table_name
        }
      }
    }
  }

  tags = merge(
    {
      Name        = local.feature_group_name
      Environment = var.environment
    },
    var.tags
  )
}
