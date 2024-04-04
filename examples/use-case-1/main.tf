# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  profile = "acai_testbed"
  region  = "eu-central-1"
  # please use the target role you need.
  # create additional providers in case your module provisions to multiple core accounts.
  assume_role {
    #role_arn = "arn:aws:iam::471112796356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Org-Mgmt Account
    #role_arn = "arn:aws:iam::590183833356:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Logging Account
    #role_arn = "arn:aws:iam::992382728088:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Core Security Account
    role_arn = "arn:aws:iam::767398146370:role/OrganizationAccountAccessRole" // ACAI AWS Testbed Workload Account
  }
}

/*
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
*/

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
    "%s_execution_policy",
    var.function_name
  )
  triggering_event_rules = [{
    name = "test_function_event"
    event_pattern = jsonencode(
      {
        "source" : ["aws.ec2"],
        "detail-type" : ["EC2 Instance State-change Notification"],
        "detail" : {
          "state" : ["terminated"]
        }
      }
    )
  }]
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
module "test_lambda" {
  # source  = "nuvibit/lambda/aws"
  # version = "~> 1.0"
  source = "../../"

  lambda_settings = {
    function_name = var.function_name
    description   = var.description
    handler       = "main.lambda_handler"
    config = {
      runtime     = "python3.12"
      memory_size = 128
      timeout     = 360
    }
    environment_variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
    tracing_mode = "PassThrough"
    package = {
      source_path = "${path.module}/lambda_files"
    }
  }

  trigger_settings = {
    schedule_expression = "cron(0 12 * * ? *)"
    event_rules         = local.triggering_event_rules
  }
  resource_tags = var.resource_tags

}
