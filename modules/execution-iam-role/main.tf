# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.00"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_role" "existing_execution_iam_role" {
  count = var.settings_new_execution_iam_role != null ? 0 : 1
  name  = var.existing_execution_iam_role_name
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  region_name_splitted = split("-", data.aws_region.current.name)
  region_name_short    = "${local.region_name_splitted[0]}${substr(local.region_name_splitted[1], 0, 1)}${local.region_name_splitted[2]}"
  create_new_execution_iam_role = var.settings_new_execution_iam_role != null
  policy_name = var.settings_new_execution_iam_role == null ? "AllowLambdaContext" : format("AllowLambdaContextFor%s-%s", replace(title(replace(replace(var.function_name, "-", " "), "_", " ")), " ", ""), local.region_name_short)
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM LAMBDA EXECUTION ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  count = local.create_new_execution_iam_role ? 1 : 0

  name                 = var.settings_new_execution_iam_role.iam_role_name
  path                 = var.settings_new_execution_iam_role.iam_role_path
  assume_role_policy   = data.aws_iam_policy_document.lambda.json
  permissions_boundary = var.settings_new_execution_iam_role.permissions_boundary_arn
  tags                 = var.resource_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM LAMBDA EXECUTION POLICY
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "TrustPolicy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ATTACH IAM POLICIES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda" {
  count = local.create_new_execution_iam_role ? length(var.settings_new_execution_iam_role.permission_policy_arns) : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = var.settings_new_execution_iam_role.permission_policy_arns[count.index]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA LOGGING - IAM POLICY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_context" {
  name   = local.policy_name
  role   = local.create_new_execution_iam_role ? aws_iam_role.lambda[0].name : data.aws_iam_role.external_execution[0].name
  policy = data.aws_iam_policy_document.lambda_context.json
}

data "aws_iam_policy_document" "lambda_context" {
  statement {
    sid    = "LogToCloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      format(
        "arn:aws:logs:%s:%s:log-group:%s:*",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        var.var.runtime_configuration.loggroup_name
      )
    ]
  }

  dynamic "statement" {
    # this conditional test is required in the event that the ARN is not known at the planning stage
    for_each = var.runtime_configuration.trigger_sqs_enabled ? ["1"] : []
    content {
      sid    = "AllowTriggerSqs"
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        var.runtime_configuration.trigger_sqs_arn
      ]
    }
  }

  dynamic "statement" {
    # this conditional test is required in the event that the ARN is not known at the planning stage
    for_each = var.runtime_configuration.encryption_enabled ? ["1"] : []
    content {
      sid    = "AllowKmsCmkAccess"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = [
        var.runtime_configuration.kms_key_arn
      ]
    }
  }
}
