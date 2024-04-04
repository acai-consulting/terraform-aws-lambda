output "lambda_name" {
  description = "Unique name identifying your Lambda Function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  description = "Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = aws_lambda_function.this.arn
}

output "lambda_version" {
  description = "Latest published version of your Lambda Function."
  value       = var.publish == true ? aws_lambda_function.this.version : ""
}

output "lambda_qualified_arn" {
  description = "ARN identifying your Lambda Function Version (if versioning is enabled via publish = true)."
  value       = var.publish == true ? aws_lambda_function.this.qualified_arn : ""
}

output "lambda_invoke_arn" {
  description = "ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri."
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_execution_role_id" {
  description = "Name of the lambda execution role."
  value       = module.execution_role.lambda_execution_role_id
}

output "lambda_execution_role_unique_id" {
  description = "Stable and unique string identifying the lambda execution role."
  value       = module.execution_role.lambda_execution_role_unique_id
}

output "lambda_execution_role_name" {
  description = "Name of the lambda execution role."
  value       = module.execution_role.lambda_execution_role_name
}

output "lambda_execution_role_arn" {
  description = "Amazon Resource Name (ARN) specifying the lambda execution role."
  value       = module.execution_role.lambda_execution_role_arn
}

output "lambda_cloudwatch_log_group_arn" {
  description = "The Amazon Resource Name (ARN) specifying the lambda log group."
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "lambda_schedule_cloudwatch_event_rule_id" {
  description = "The name of the lambda scheduling rule."
  value       = var.schedule_expression != null ? aws_cloudwatch_event_rule.schedule[0].id : ""
}

output "lambda_schedule_cloudwatch_event_rule_arn" {
  description = "The Amazon Resource Name (ARN) of the lambda scheduling rule."
  value       = var.schedule_expression != null ? aws_cloudwatch_event_rule.schedule[0].arn : ""
}

output "lambda_pattern_cloudwatch_event_rule_ids" {
  description = "The name of the lambda pattern rule."
  # tflint-ignore: terraform_empty_list_equality
  value = var.event_patterns != [] ? [for k, v in aws_cloudwatch_event_rule.pattern : v.id] : []
}

output "lambda_pattern_cloudwatch_event_rule_arns" {
  description = "The Amazon Resource Name (ARN) of the lambda pattern rule."
  # tflint-ignore: terraform_empty_list_equality
  value = var.event_patterns != [] ? [for k, v in aws_cloudwatch_event_rule.pattern : v.arn] : []
}

output "trigger_sqs_arn" {
  description = "ARN of the optional Trigger-SQS."
  value       = var.trigger_sqs_enabled == true ? aws_sqs_queue.lambda_trigger[0].arn : null
}

output "trigger_sqs_name" {
  description = "Name of the optional Trigger-SQS."
  value       = var.trigger_sqs_enabled == true ? aws_sqs_queue.lambda_trigger[0].name : null
}

output "trigger_sqs_id" {
  description = "ID of the optional Trigger-SQS."
  value       = var.trigger_sqs_enabled == true ? aws_sqs_queue.lambda_trigger[0].id : null
}
