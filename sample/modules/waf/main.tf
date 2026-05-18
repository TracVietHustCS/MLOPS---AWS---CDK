# =============================================================================
# AWS WAF Module
# =============================================================================
# Web Application Firewall for API Gateway protection
# Uses AWS Managed Rules
# =============================================================================

# -----------------------------------------------------------------------------
# WAF Web ACL
# -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  name        = "${var.name_prefix}-${var.environment}-waf"
  description = "WAF for API Gateway - ${var.environment}"
  scope       = var.scope # REGIONAL for API Gateway, CLOUDFRONT for CloudFront

  default_action {
    allow {}
  }

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - SQL Injection
  dynamic "rule" {
    for_each = var.enable_sql_injection_protection ? [1] : []
    content {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 3

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesSQLiRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-sqli"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rate limiting rule
  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 10

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-rate-limit"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-waf"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# WAF Association with API Gateway
# -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "api_gateway" {
  count        = var.enable_api_gateway_association ? 1 : 0
  resource_arn = var.api_gateway_stage_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for WAF
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf" {
  count             = var.enable_logging ? 1 : 0
  name              = "aws-waf-logs-${var.name_prefix}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "aws-waf-logs-${var.name_prefix}-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.enable_logging ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
