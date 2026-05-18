data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  job_definition_name      = "${var.name_prefix}-${var.environment}-${var.monitoring_job_name}"
  monitoring_schedule_name = "${var.name_prefix}-${var.environment}-${var.monitoring_job_name}-schedule"
}

resource "aws_sagemaker_data_quality_job_definition" "data_quality" {
  name     = local.job_definition_name
  role_arn = var.role_arn

  data_quality_app_specification {
    image_uri = coalesce(
      var.custom_image_uri,
      "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/sagemaker-model-monitor-analyzer"
    )

    environment = var.environment_variables
  }

  data_quality_job_input {
    endpoint_input {
      endpoint_name             = var.endpoint_name
      local_path                = var.input_local_path
      s3_data_distribution_type = var.s3_data_distribution_type
      s3_input_mode             = var.s3_input_mode
    }
  }

  data_quality_job_output_config {
    monitoring_outputs {
      s3_output {
        s3_uri         = var.output_s3_uri
        local_path     = var.output_local_path
        s3_upload_mode = var.s3_upload_mode
      }
    }

    kms_key_id = var.kms_key_id
  }

  job_resources {
    cluster_config {
      instance_count    = var.instance_count
      instance_type     = var.instance_type
      volume_size_in_gb = var.volume_size_in_gb

      volume_kms_key_id = var.volume_kms_key_id
    }
  }

  dynamic "network_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      enable_inter_container_traffic_encryption = var.enable_inter_container_traffic_encryption
      enable_network_isolation                  = var.enable_network_isolation

      vpc_config {
        subnets            = var.subnet_ids
        security_group_ids = var.security_group_ids
      }
    }
  }

  dynamic "stopping_condition" {
    for_each = var.max_runtime_in_seconds != null ? [1] : []
    content {
      max_runtime_in_seconds = var.max_runtime_in_seconds
    }
  }

  tags = merge(
    {
      Name        = local.job_definition_name
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_sagemaker_monitoring_schedule" "schedule" {
  count = var.create_monitoring_schedule ? 1 : 0

  name = local.monitoring_schedule_name

  monitoring_schedule_config {
    monitoring_job_definition_name = aws_sagemaker_data_quality_job_definition.data_quality.name
    monitoring_type                = "DataQuality"

    schedule_config {
      schedule_expression = var.schedule_expression
    }
  }

  tags = merge(
    {
      Name        = local.monitoring_schedule_name
      Environment = var.environment
    },
    var.tags
  )
}
