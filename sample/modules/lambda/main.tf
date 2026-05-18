resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.name_prefix}-${var.environment}-${var.function_name}"
  role             = var.lambda_role_arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = var.runtime
  layers           = length(var.layers) > 0 ? var.layers : null
  timeout          = var.timeout
  memory_size      = var.memory_size

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.function_name}"
      Environment = var.environment
    }
  )

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.module}/.terraform/${var.function_name}.zip"
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.eventbridge_rules

  name                = "${var.name_prefix}-${var.environment}-${each.key}"
  description         = each.value.description
  schedule_expression = lookup(each.value, "schedule_expression", null)
  event_pattern       = lookup(each.value, "event_pattern", null)

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-${var.environment}-${each.key}"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = var.eventbridge_rules

  rule = aws_cloudwatch_event_rule.this[each.key].name
  arn  = aws_lambda_function.this.arn

  input = lookup(each.value, "input", null)
}

resource "aws_lambda_permission" "eventbridge" {
  for_each = var.eventbridge_rules

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this[each.key].arn
}
