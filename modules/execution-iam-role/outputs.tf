output "lambda_execution_iam_role" {
  description = "Information about the Lambda execution role."
  value = {
    "id"          = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].id : data.aws_iam_role.existing_execution_iam_role[0].id,
    "unique_id"   = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].unique_id : data.aws_iam_role.existing_execution_iam_role[0].unique_id,
    "name"        = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].name : data.aws_iam_role.existing_execution_iam_role[0].name,
    "arn"         = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].arn : data.aws_iam_role.existing_execution_iam_role[0].arn
    "aws_iam_policy_document"         = data.aws_iam_policy_document.new_lambda_permission_policies
    "local.create_new_execution_iam_role" = local.create_new_execution_iam_role
    "local.new_execution_iam_role.permission_policy_json_list"= local.new_execution_iam_role.permission_policy_json_list
  }
}
