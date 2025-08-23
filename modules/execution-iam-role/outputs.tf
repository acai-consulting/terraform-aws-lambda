output "id" {
  description = "The ID of the Lambda execution IAM role."
  value       = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].id : null
}

output "unique_id" {
  description = "The unique ID of the Lambda execution IAM role."
  value       = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].unique_id : null
}

output "name" {
  description = "The name of the Lambda execution IAM role."
  value       = local.execution_iam_role_name
}

output "arn" {
  description = "The ARN of the Lambda execution IAM role."
  value       = local.execution_iam_role_arn
}
