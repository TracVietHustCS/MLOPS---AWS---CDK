resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  idle_timeout                     = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_lb_target_group" "main" {
  for_each = var.target_groups

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  dynamic "health_check" {
    for_each = each.value.health_check_enabled ? [1] : []
    content {
      enabled             = true
      healthy_threshold   = lookup(each.value, "health_check_healthy_threshold", 2)
      unhealthy_threshold = lookup(each.value, "health_check_unhealthy_threshold", 2)
      timeout             = lookup(each.value, "health_check_timeout", 5)
      interval            = lookup(each.value, "health_check_interval", 30)
      path                = lookup(each.value, "health_check_path", "/health")
      protocol            = lookup(each.value, "health_check_protocol", each.value.protocol)
      matcher             = lookup(each.value, "health_check_matcher", "200")
    }
  }

  dynamic "health_check" {
    for_each = !each.value.health_check_enabled ? [1] : []
    content {
      enabled = false
    }
  }

  deregistration_delay = lookup(each.value, "deregistration_delay", 300)

  dynamic "stickiness" {
    for_each = lookup(each.value, "stickiness_enabled", false) ? [1] : []
    content {
      type            = lookup(each.value, "stickiness_type", "lb_cookie")
      cookie_duration = lookup(each.value, "stickiness_cookie_duration", 86400)
      enabled         = true
    }
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.value.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != null ? "redirect" : lookup(var.default_action, "type", "fixed-response")

    dynamic "redirect" {
      for_each = var.certificate_arn != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = var.certificate_arn == null && lookup(var.default_action, "type", "fixed-response") == "fixed-response" ? [1] : []
      content {
        content_type = lookup(var.default_action, "content_type", "text/plain")
        message_body = lookup(var.default_action, "message_body", "OK")
        status_code  = lookup(var.default_action, "status_code", "200")
      }
    }

    dynamic "forward" {
      for_each = var.certificate_arn == null && lookup(var.default_action, "type", "") == "forward" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.main[var.default_action.target_group_key].arn
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = lookup(var.default_action, "type", "fixed-response")

    dynamic "fixed_response" {
      for_each = lookup(var.default_action, "type", "fixed-response") == "fixed-response" ? [1] : []
      content {
        content_type = lookup(var.default_action, "content_type", "text/plain")
        message_body = lookup(var.default_action, "message_body", "OK")
        status_code  = lookup(var.default_action, "status_code", "200")
      }
    }

    dynamic "forward" {
      for_each = lookup(var.default_action, "type", "") == "forward" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.main[var.default_action.target_group_key].arn
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "http" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.value.target_group_key].arn
  }

  dynamic "condition" {
    for_each = lookup(each.value, "path_patterns", null) != null ? [1] : []
    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "host_headers", null) != null ? [1] : []
    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "https" {
  for_each = var.certificate_arn != null ? var.listener_rules : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.value.target_group_key].arn
  }

  dynamic "condition" {
    for_each = lookup(each.value, "path_patterns", null) != null ? [1] : []
    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "host_headers", null) != null ? [1] : []
    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }

  tags = var.tags
}
