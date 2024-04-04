

output "lambda_execution_iam_role_info" {
  description = "Information about the Lambda execution role."
  value = module.lambda_execution_iam_role.lambda_execution_iam_role_info
}