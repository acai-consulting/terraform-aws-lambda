# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.00"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_role" "existing_execution_iam_role" {
  count = local.create_new_execution_iam_role == false ? 1 : 0
  name  = var.execution_iam_role_settings.existing_iam_role_name
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  region_name_length = length(data.aws_region.current.name)
  region_name_short = format("%s%s%s",
    substr(data.aws_region.current.name, 0, 2),
    substr(data.aws_region.current.name, 3, 1),                           // Assuming you want the character at index 3 (fourth character)
    substr(data.aws_region.current.name, local.region_name_length - 1, 1) // Get the last character
  )
  create_new_execution_iam_role = var.execution_iam_role_settings.new_iam_role != null

  new_execution_iam_role_name = local.create_new_execution_iam_role ? coalesce(
    var.execution_iam_role_settings.new_iam_role.name,
    "${var.runtime_configuration.lambda_name}_execution_role"
  ) : ""

  new_execution_iam_role = var.execution_iam_role_settings.new_iam_role
  policy_name_suffix     = local.create_new_execution_iam_role ? format("For%s-%s", replace(title(replace(replace(var.runtime_configuration.lambda_name, "-", " "), "_", " ")), " ", ""), local.region_name_short) : ""
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA EXECUTION IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "execution_role" {
  count = local.create_new_execution_iam_role ? 1 : 0

  name                 = local.new_execution_iam_role_name
  path                 = local.new_execution_iam_role.path
  assume_role_policy   = data.aws_iam_policy_document.execution_role_trust.json
  permissions_boundary = local.new_execution_iam_role.permissions_boundary_arn
  tags                 = var.resource_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA EXECUTION IAM POLICY
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "execution_role_trust" {
  statement {
    sid     = "TrustPolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ATTACH IAM POLICIES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "execution_role" {
  count      = local.create_new_execution_iam_role ? length(var.execution_iam_role_settings.new_iam_role.permission_policy_arn_list) : 0
  role       = aws_iam_role.execution_role[0].name
  policy_arn = local.new_execution_iam_role.permission_policy_arn_list[count.index]
}

resource "aws_iam_role_policy" "lambda_context" {
  name   = "AllowLambdaContext${local.policy_name_suffix}"
  role   = local.create_new_execution_iam_role ? aws_iam_role.execution_role[0].name : data.aws_iam_role.existing_execution_iam_role[0].name
  policy = data.aws_iam_policy_document.lambda_context.json
}

data "aws_iam_policy_document" "lambda_context" {
  statement {
    sid       = "LogToCloudWatch"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.runtime_configuration.loggroup_name}:*"]
  }

  dynamic "statement" {
    for_each = var.existing_kms_cmk_arn != null ? [1] : []
    content {
      sid       = "AllowKmsCmkAccess"
      effect    = "Allow"
      actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
      resources = [var.existing_kms_cmk_arn]
    }
  }
}


resource "aws_iam_role_policy" "new_lambda_permission_policies" {
  count = local.create_new_execution_iam_role && can(local.new_execution_iam_role.permission_policy_json_list) ? 1 : 0

  name   = "AllowCustomPermissions${local.policy_name_suffix}"
  role   = aws_iam_role.execution_role[0].name
  policy = data.aws_iam_policy_document.new_lambda_permission_policies[0].json
}

data "aws_iam_policy_document" "new_lambda_permission_policies" {
  count = local.create_new_execution_iam_role && can(local.new_execution_iam_role.permission_policy_json_list) ? 1 : 0

  source_policy_documents = local.new_execution_iam_role.permission_policy_json_list
}