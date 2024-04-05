# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
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

locals {
  triggering_event_rules = [{
    name = "use_case_2_event"
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

data "aws_iam_policy_document" "lambda_permission" {
  statement {
    effect = "Allow"
    actions = [
      "events:List*",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

module "use_case_2_lambda" {
  source = "../../"

  lambda_settings = {
    function_name = var.function_name
    description   = "This Lambda will list all Event-Rules and and EC2 instances and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime     = "python3.12"
      memory_size = 512
      timeout     = 360
    }
    environment_variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
    package = {
      source_path = "${path.module}/lambda_files"
    }
  }
  trigger_settings = {
    schedule_expression = "cron(0 1 * * ? *)"
    event_rules         = local.triggering_event_rules
  }
  execution_iam_role_settings = {
    new_iam_role = {
      permission_policy_json_list = [
        data.aws_iam_policy_document.lambda_permission.json
      ]
    }
  }
  resource_tags = var.resource_tags
}

resource "aws_lambda_invocation" "use_case_2_lambda" {
  function_name = module.use_case_2_lambda.lambda.name

  input = <<JSON
{
}
JSON
  depends_on = [
    module.use_case_2_lambda
  ]
}

