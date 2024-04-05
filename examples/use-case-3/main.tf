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

# ---------------------------------------------------------------------------------------------------------------------
# ¦ SHARED IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "use_case_3_shared_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })

  inline_policy {
    name   = "inline_lambda_execution_policy"
    policy = data.aws_iam_policy_document.lambda_permission.json
  }
}

#tfsec:ignore:avd-aws-0057
data "aws_iam_policy_document" "lambda_permission" {
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "iam:ListRoles",
      "events:List*",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ Lambda 1
# ---------------------------------------------------------------------------------------------------------------------
module "use_case_3_lambda1" {
  source = "../../"

  lambda_settings = {
    function_name = "${var.function_name}-1"
    description   = "This Lambda will list all CloudWatch LogGroups and IAM Roles and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime = "python3.12"
    }
    environment_variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
    package = {
      source_path = "${path.module}/lambda1_files"
    }
  }
  execution_iam_role_settings = {
    existing_iam_role_name = aws_iam_role.lambda_exec_role.name
  }
  resource_tags = var.resource_tags
  depends_on = [
    aws_iam_role.lambda_exec_role
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ Lambda 2
# ---------------------------------------------------------------------------------------------------------------------
locals {
  triggering_event_rules = [{
    name = "use_case_3_event"
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

module "use_case_3_lambda2" {
  source = "../../"

  lambda_settings = {
    function_name = "${var.function_name}-2"
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
      source_path = "${path.module}/lambda2_files"
    }
  }
  trigger_settings = {
    schedule_expression = "cron(0 1 * * ? *)"
    event_rules         = local.triggering_event_rules
  }
  execution_iam_role_settings = {
    existing_iam_role_name = aws_iam_role.lambda_exec_role.name
  }
  resource_tags = var.resource_tags
  depends_on = [
    aws_iam_role.lambda_exec_role
  ]
}



resource "aws_lambda_invocation" "use_case_3_lambda1" {
  function_name = module.use_case_3_lambda1.lambda.name

  input = <<JSON
{
}
JSON
  depends_on = [
    module.use_case_3_lambda1
  ]
}


resource "aws_lambda_invocation" "use_case_3_lambda2" {
  function_name = module.use_case_3_lambda2.lambda.name

  input = <<JSON
{
}
JSON
  depends_on = [
    module.use_case_3_lambda2
  ]
}

