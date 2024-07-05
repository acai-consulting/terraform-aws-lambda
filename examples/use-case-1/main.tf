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

# ---------------------------------------------------------------------------------------------------------------------
# ¦ USE_CASE_1_LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
module "use_case_1_lambda" {
  source = "../../"

  lambda_settings = {
    function_name = "${var.function_name}_1"
    description   = "This Lambda will list all CloudWatch LogGroups and IAM Roles and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime = "python3.10"
    }
    environment_variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
    package = {
      source_path = "${path.module}/lambda-files"
      files_to_inject = {
        "sub-folder/test.txt" = <<-EOT
hello2
```python
account_context = {
    "accountId": "471112796356",
    "accountName": "acai_testbed-lab1_wl2",
    "accountStatus": "ACTIVE"
}
```
EOT
      }
    }
  }
  execution_iam_role_settings = {
    new_iam_role = {
      permission_policy_json_list = [
        data.aws_iam_policy_document.lambda_permission.json
      ]
    }
  }
  #worker_is_windows = true
  resource_tags = var.resource_tags
}

resource "aws_lambda_invocation" "use_case_1_lambda" {
  function_name = module.use_case_1_lambda.lambda.name

  input = <<JSON
{
}
JSON
  depends_on = [
    module.use_case_1_lambda
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ USE_CASE_1_1_LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
locals {
  file_paths = fileset("${path.module}/semper-policies/", "**/*.json")
  semper_policies_map = {
    for file in local.file_paths :
    "semper-policies/${file}" => file("${path.module}/semper-policies/${file}")
  }
}

module "use_case_1_2_lambda" {
  source = "../../"

  lambda_settings = {
    function_name = "${var.function_name}_2"
    description   = "This sample will inject the content of a 'local' folder into the Lambda package"
    handler       = "main.lambda_handler"
    config = {
      runtime = "python3.10"
    }
    package = {
      source_path = "${path.module}/lambda-files"
      files_to_inject = merge(
        local.semper_policies_map,
        { "README.md" : "Override README.md" }
      )
    }
  }
  execution_iam_role_settings = {
    new_iam_role = {}
  }
  #worker_is_windows = true
  resource_tags = var.resource_tags
}
