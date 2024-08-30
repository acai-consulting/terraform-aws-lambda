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
# ¦ USE_CASE_5_LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
locals {
  file_paths = fileset("${path.module}/semper-policies/", "**/*.json")
  semper_policies_map = {
    for file in local.file_paths :
    "semper-policies/${file}" => file("${path.module}/semper-policies/${file}")
  }
}

module "use_case_5_lambda" {
  #checkov:skip=CKV_AWS_50
  source = "../../"

  lambda_settings = {
    function_name = "${var.function_name}_5"
    description   = "This sample will inject the content of a 'local' folder into the Lambda package"
    handler       = "main.lambda_handler"
    config = {
      runtime = "python3.11"
    }
    package = {
      source_path = "${path.module}/lambda-files"
      files_to_inject = merge(
        local.semper_policies_map,
        {
          "README.md" : "Override README.md"
          "sub-folder/test.json" = <<-EOT
{
    "accountId": "${data.aws_caller_identity.current.account_id}",
    "accountName": "acai_testbed-lab1_wl2",
    "accountStatus": "ACTIVE"
}
EOT
        }
      )
    }
  }
  execution_iam_role_settings = {
    new_iam_role = {}
  }
  #worker_is_windows = true
  resource_tags = var.resource_tags
}

resource "aws_lambda_invocation" "use_case_5_lambda" {
  function_name = module.use_case_5_lambda.lambda.name

  input = <<JSON
{
}
JSON
  depends_on = [
    module.use_case_5_lambda
  ]
}
