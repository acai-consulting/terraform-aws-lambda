output "lambda_execution_iam_role" {
  description = "Information about the Lambda execution role."
  value = {
    "id"          = local.create_new_execution_iam_role ? aws_iam_role.lambda[0].id : data.aws_iam_role.existing_execution_iam_role[0].id,
    "unique_id"   = local.create_new_execution_iam_role ? aws_iam_role.lambda[0].unique_id : data.aws_iam_role.existing_execution_iam_role[0].unique_id,
    "name"        = local.create_new_execution_iam_role ? aws_iam_role.lambda[0].name : data.aws_iam_role.existing_execution_iam_role[0].name,
    "arn"         = local.create_new_execution_iam_role ? aws_iam_role.lambda[0].arn : data.aws_iam_role.existing_execution_iam_role[0].arn
  }
}
