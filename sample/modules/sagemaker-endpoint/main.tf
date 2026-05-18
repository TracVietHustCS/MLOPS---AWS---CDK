data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_sagemaker_model" "model" {
  name               = "${var.name_prefix}-${var.environment}-${var.model_name}"
  execution_role_arn = var.execution_role_arn

  primary_container {
    image          = var.container_image
    model_data_url = "s3://${var.model_bucket_name}/${var.model_s3_key}"
    environment = merge(
      var.container_environment,
      {
        SAGEMAKER_ENDPOINT_NAME             = "${var.name_prefix}-${var.environment}-${var.model_name}"
        SAGEMAKER_ENABLE_CLOUDWATCH_METRICS = "true"
        publish_cloudwatch_metrics          = "Enabled"
        MONITORING_SCHEDULE_NAME            = "${var.name_prefix}-${var.environment}-${var.model_name}-monitoring"
        METRICS_PUBLISH_INTERVAL            = "60"
      }
    )
  }

  dynamic "vpc_config" {
    for_each = var.security_group_ids != null ? [1] : []
    content {
      subnets            = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.model_name}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_sagemaker_endpoint_configuration" "config" {
  name = "${var.name_prefix}-${var.environment}-${var.model_name}-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.model.name
    instance_type          = var.instance_type
    initial_instance_count = var.initial_instance_count
    initial_variant_weight = 1.0
  }

  tags = merge(
    {
      Name                 = "${var.name_prefix}-${var.model_name}-config"
      Environment          = var.environment
      AutoSchedule         = var.enable_auto_schedule ? "true" : "false"
      OriginalEndpointName = "${var.name_prefix}-${var.environment}-${var.model_name}"
    },
    var.tags
  )
}

resource "aws_sagemaker_endpoint" "endpoint" {
  count                = var.create_endpoint ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-${var.model_name}"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.config.name

  tags = merge(
    {
      Name         = "${var.name_prefix}-${var.model_name}-endpoint"
      Environment  = var.environment
      AutoSchedule = var.enable_auto_schedule ? "true" : "false"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_appautoscaling_target" "endpoint" {
  count              = var.create_endpoint && var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_instance_count
  min_capacity       = var.min_instance_count
  resource_id        = "endpoint/${aws_sagemaker_endpoint.endpoint[0].name}/variant/AllTraffic"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"

  depends_on = [aws_sagemaker_endpoint.endpoint]
}

# PRIMARY: Concurrent requests-based autoscaling policy
resource "aws_appautoscaling_policy" "endpoint_concurrent" {
  count              = var.create_endpoint && var.enable_autoscaling ? 1 : 0
  name               = "${var.name_prefix}-${var.environment}-${var.model_name}-concurrent-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.endpoint[0].resource_id
  scalable_dimension = aws_appautoscaling_target.endpoint[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.endpoint[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.target_concurrent_requests

    customized_metric_specification {
      metric_name = "ConcurrentRequestsPerModel"
      namespace   = "AWS/SageMaker"
      statistic   = "Average"

      dimensions {
        name  = "EndpointName"
        value = aws_sagemaker_endpoint.endpoint[0].name
      }

      dimensions {
        name  = "VariantName"
        value = "AllTraffic"
      }
    }

    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
