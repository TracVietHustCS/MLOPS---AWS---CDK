# =============================================================================
# SageMaker Training Job Module
# =============================================================================
# Machine Learning model training infrastructure
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Training Job Definition (using Step Functions for orchestration)
# -----------------------------------------------------------------------------
resource "aws_sfn_state_machine" "training" {
  name     = "${var.name_prefix}-${var.environment}-training-workflow"
  role_arn = var.execution_role_arn != null ? var.execution_role_arn : aws_iam_role.training[0].arn

  definition = templatefile("${path.module}/workflow.json.tpl", {
    name_prefix                       = var.name_prefix
    environment                       = var.environment
    training_image                    = var.training_image
    training_input_mode               = var.training_input_mode
    sagemaker_role_arn                = var.sagemaker_role_arn
    training_data_content_type        = var.training_data_content_type
    output_bucket                     = var.output_bucket
    output_prefix                     = var.output_prefix
    kms_key_arn                       = var.kms_key_arn
    training_instance_type            = var.training_instance_type
    training_instance_count           = var.training_instance_count
    training_volume_size              = var.training_volume_size
    max_runtime_seconds               = var.max_runtime_seconds
    enable_network_isolation          = var.enable_network_isolation
    enable_inter_container_encryption = var.enable_inter_container_encryption
    inference_image                   = var.inference_image != null ? var.inference_image : var.training_image
    vpc_config                        = var.vpc_config
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.training.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-training-workflow"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "training" {
  name              = "/aws/vendedlogs/states/${var.name_prefix}-${var.environment}-training"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-training-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# IAM Role for Step Functions
# -----------------------------------------------------------------------------
resource "aws_iam_role" "training" {
  count                = var.execution_role_arn == null ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-training-sfn-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "training" {
  count = var.execution_role_arn == null ? 1 : 0
  name  = "training-workflow-policy"
  role  = aws_iam_role.training[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:StopTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:DescribeModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.sagemaker_role_arn
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "arn:aws:events:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForSageMakerTrainingJobsRule"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# EventBridge Rule for Scheduled Training (Optional)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "scheduled_training" {
  count               = var.enable_scheduled_training ? 1 : 0
  name                = "${var.name_prefix}-${var.environment}-scheduled-training"
  description         = "Trigger training job on schedule"
  schedule_expression = var.training_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "scheduled_training" {
  count     = var.enable_scheduled_training ? 1 : 0
  rule      = aws_cloudwatch_event_rule.scheduled_training[0].name
  target_id = "TriggerTraining"
  arn       = aws_sfn_state_machine.training.arn
  role_arn  = aws_iam_role.eventbridge[0].arn

  input = jsonencode({
    TrainingDataS3Uri = var.default_training_data_uri
  })
}

resource "aws_iam_role" "eventbridge" {
  count                = var.enable_scheduled_training ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-training-eventbridge-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge" {
  count = var.enable_scheduled_training ? 1 : 0
  name  = "invoke-step-functions"
  role  = aws_iam_role.eventbridge[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.training.arn
    }]
  })
}
