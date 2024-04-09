output "lambda" {
  description = "Information about the Lambda."
  value = {
    name          = aws_lambda_function.this.function_name
    arn           = aws_lambda_function.this.arn
    version       = aws_lambda_function.this.version
    qualified_arn = aws_lambda_function.this.qualified_arn
    invoke_arn    = aws_lambda_function.this.invoke_arn
  }
}

output "trigger" {
  description = "Information about the Lambda triggers."
  value       = var.trigger_settings != {} ? module.lambda_trigger[0] : null
}

output "execution_iam_role" {
  description = "Information about the Lambda execution role."
  value       = module.lambda_execution_iam_role
}
