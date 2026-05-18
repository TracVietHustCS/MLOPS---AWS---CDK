output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "eventbridge_rule_arns" {
  description = "ARNs of EventBridge rules"
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.arn }
}
