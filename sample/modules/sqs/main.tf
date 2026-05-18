# SQS Queue Module

resource "aws_sqs_queue" "main" {
  name                       = "${var.name_prefix}-${var.environment}-${var.queue_name}"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  receive_wait_time_seconds  = var.receive_wait_time

  # Dead letter queue
  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.queue_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                       = "${var.name_prefix}-${var.environment}-${var.queue_name}-dlq"
  message_retention_seconds  = var.dlq_message_retention
  visibility_timeout_seconds = var.visibility_timeout

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.queue_name}-dlq"
      Environment = var.environment
    },
    var.tags
  )
}
