# =============================================================================
# CloudWatch Dashboard Module
# =============================================================================
# Creates CloudWatch dashboards and alarms for MLOps monitoring
# =============================================================================

data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name_prefix}-${var.environment}-${var.dashboard_name}"
  dashboard_body = var.dashboard_body
}

# Metric alarms
resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = var.metric_alarms

  alarm_name          = "${var.name_prefix}-${var.environment}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = lookup(each.value, "description", "Managed by Terraform")
  alarm_actions       = lookup(each.value, "alarm_actions", [])
  ok_actions          = lookup(each.value, "ok_actions", [])

  dimensions = lookup(each.value, "dimensions", {})

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )
}
