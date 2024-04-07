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
