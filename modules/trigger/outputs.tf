output "trigger_sqs_arn" {
  description = "The ARN of the SQS queue configured as a trigger for the Lambda function."
  value       = var.trigger_settings.sqs != null ? aws_sqs_queue.lambda_trigger[0].arn : null
}

output "scheduler_arn" {
  description = "The ARN of the CloudWatch event rule for schedule."
  value       = var.trigger_settings.schedule_expression != null ? aws_cloudwatch_event_rule.schedule[0].arn : null
}

output "cloudwatch_event_rule_arns" {
  description = "ARNs of the created CloudWatch event rules."
  value       = var.trigger_settings.event_rules != null ? [for rule in aws_cloudwatch_event_rule.pattern : rule.arn] : []
}
