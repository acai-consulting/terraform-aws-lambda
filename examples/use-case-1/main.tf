# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  # please use the target role you need.
  # create additional providers in case your module provisions to multiple core accounts.
  assume_role {
    #role_arn = "arn:aws:iam::471112796356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Org-Mgmt Account
    #role_arn = "arn:aws:iam::590183833356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Logging Account
    #role_arn = "arn:aws:iam::992382728088:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Security Account
    role_arn = "arn:aws:iam::767398146370:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Workload Account
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ BACKEND
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "remote" {
    organization = "acai"
    hostname     = "app.terraform.io"

    workspaces {
      name = "aws-testbed"
    }
  }

}

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
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  execution_policy_name = format(
    "%s_execution_policy-%s",
    var.function_name,
    random_string.suffix.result,
  )
  event_patterns = [
    jsonencode(
      {
        "source" : ["aws.ec2"],
        "detail-type" : ["EC2 Instance State-change Notification"],
        "detail" : {
          "state" : ["terminated"]
        }
      }
    )
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ RANDOM SUFFIX
# ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 16
  numeric = true
  lower   = true
  upper   = true
  special = false
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA EXECUTION POLICIES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "list_users" {
  name   = local.execution_policy_name
  policy = data.aws_iam_policy_document.list_users.json
}

data "aws_iam_policy_document" "list_users" {
  # enable IAM in logging account
  statement {
    sid       = "EnableOrganization"
    effect    = "Allow"
    actions   = ["iam:ListUsers"]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-lambda-enable-tracing
module "lambda" {
  # source  = "nuvibit/lambda/aws"
  # version = "~> 1.0"
  source = "../../"

  function_name           = var.function_name
  description             = var.description
  package_source_path     = "${path.module}/lambda_files"
  handler                 = "main.lambda_handler"
  schedule_expression     = "cron(0 12 * * ? *)"
  event_patterns          = local.event_patterns
  iam_execution_role_path = "/lambda/"
  iam_execution_policy_arns = [
    aws_iam_policy.list_users.arn
  ]
  environment_variables = {
    ACCOUNT_ID = data.aws_caller_identity.current.account_id
  }
  memory_size          = 128
  timeout              = 360
  runtime              = "python3.9"
  resource_tags        = var.resource_tags
  resource_name_suffix = random_string.suffix.result
  tracing_mode         = "PassThrough"
}
