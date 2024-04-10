# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ SHARED KMS CMK
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "lambda_cmk" {
  description             = "KMS CMK for Lambda Encryption/Decryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.lambda_kms_policy.json
}
resource "aws_kms_alias" "lambda_cmk_alias" {
  name          = "alias/use_case_4_cmk"
  target_key_id = aws_kms_key.lambda_cmk.key_id
}
/*
  #checkov:skip=CKV_AWS_109 : Example only
  #checkov:skip=CKV_AWS_111 : Example only
  #checkov:skip=CKV_AWS_283 : Example only
  #checkov:skip=CKV_AWS_356 : Example only
*/

#tfsec:ignore:avd-aws-0057
data "aws_iam_policy_document" "lambda_kms_policy" {
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "Service"
      identifiers = [
        "logs.amazonaws.com",
        "lambda.amazonaws.com",
        "sns.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ INBOUND SNS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_sns_topic" "triggering_sns" {
  name              = format("%s-feed", var.function_name)
  kms_master_key_id = aws_kms_key.lambda_cmk.key_id
}

resource "aws_sns_topic_policy" "triggering_sns" {
  arn    = aws_sns_topic.triggering_sns.arn
  policy = data.aws_iam_policy_document.triggering_sns.json
}

data "aws_iam_policy_document" "triggering_sns" {
  statement {
    sid     = "AllowedPublishers"
    actions = ["sns:Publish"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format("arn:aws:iam::%s:root", data.aws_caller_identity.current.id)
      ]
    }
    resources = [aws_sns_topic.triggering_sns.arn]
  }
  statement {
    sid     = "AllowedSubscribers"
    actions = ["sns:Subscribe"]
    effect  = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format("arn:aws:iam::%s:root", data.aws_caller_identity.current.id)
      ]
    }
    resources = [aws_sns_topic.triggering_sns.arn]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ Lambda
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_permission" {
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

module "use_case_4_lambda" {
  source = "../../"

  lambda_settings = {
    function_name = var.function_name
    description   = "This Lambda will list all CloudWatch LogGroups and IAM Roles and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime = "python3.10"
    }
    environment_variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
    package = {
      source_path = "${path.module}/lambda_files"
    }
  }
  trigger_settings = {
    sqs = {
      inbound_sns_topics = [{
        sns_arn            = aws_sns_topic.triggering_sns.arn
        filter_policy_json = null
      }]
    }
  }
  execution_iam_role_settings = {
    new_iam_role = {
      permission_policy_json_list = [
        data.aws_iam_policy_document.lambda_permission.json
      ]
    }
  }
  existing_kms_cmk_arn = aws_kms_key.lambda_cmk.arn
  resource_tags        = var.resource_tags
}

resource "aws_lambda_invocation" "use_case_4_lambda" {
  function_name = module.use_case_4_lambda.lambda.name

  input = <<JSON
{
}
JSON
  depends_on = [
    module.use_case_4_lambda
  ]
}

