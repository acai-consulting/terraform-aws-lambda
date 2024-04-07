output "id" {
  description = "The ID of the Lambda execution IAM role."
  value       = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].id : data.aws_iam_role.existing_execution_iam_role[0].id
}

output "unique_id" {
  description = "The unique ID of the Lambda execution IAM role."
  value       = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].unique_id : data.aws_iam_role.existing_execution_iam_role[0].unique_id
}

output "name" {
  description = "The name of the Lambda execution IAM role."
  value       = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].name : data.aws_iam_role.existing_execution_iam_role[0].name
}

output "arn" {
  description = "The ARN of the Lambda execution IAM role."
  value       = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].arn : data.aws_iam_role.existing_execution_iam_role[0].arn
}

output "policy_document" {
  description = "The IAM policy document associated with the Lambda execution role."
  value       = data.aws_iam_policy_document.new_lambda_permission_policies.json
}
