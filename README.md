# terraform-aws-lambda

<!-- LOGO -->
<a href="https://acai.gmbh">
  <img src="https://github.com/acai-consulting/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI" align="right" height="75" />
</a>

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url]
[![Terraform Version][terraform-version-shield]][terraform-version-url]

<!-- DESCRIPTION -->
[Terraform][terraform-url] module to deploy Lambda resources on [AWS][aws-url]


<!-- ARCHITECTURE -->
## Architecture

![architecture][architecture-png]

<!-- FEATURES -->
## Features
* Creates a Lambda Function
* Creates a CloudWatch Log Group for Lambda logs
* Execution IAM Role
  * Option 1: Create a new Lambda Execution IAM Role and attach internal and provided policies
  * Option 2: Provide the ARN of an existing Lambda Execution IAM Role
* Triggers (optional)
  * Create a SQS for triggering the Lambda
  * Create a scheduling Event Rule
  * Create CloudWatch Event Rules

<!-- EXAMPLES -->
## Examples

### Use-Case-1
This Lambda will list all CloudWatch LogGroups and IAM Roles and return them as JSON.
This Use-Case will create a Lambda, with a new Execution IAM Role and provides a lambda_permission policy-snip to perform the tasks.

Location: [`./examples/use-case-1`](./examples/use-case-1/)
``` hcl
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_permission" {
  # enable IAM in logging account
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

module "use_case_1_lambda" {
  source = "../../"

  lambda_settings = {
    function_name = var.function_name
    description   = "This Lambda will list all CloudWatch LogGroups and IAM Roles and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime     = "python3.12"
      memory_size = 128
      timeout     = 360
    }
    environment_variables = {
      ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
    package = {
      source_path = "${path.module}/lambda_files"
    }
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
```

### Use-Case-2
This Lambda will list all Event-Rules and return them as JSON
This Use-Case will create a Lambda, with a new Execution IAM Role and provides a lambda_permission policy-snip to perform the tasks.
The Lambda will be scheduled and will be triggered by an Event Rule, listening for terminated EC2 instances.

Location: [`./examples/use-case-2`](./examples/use-case-2/)
``` hcl
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
    effect    = "Allow"
    actions   = [
      "events:List*",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

module "test_lambda" {
  source = "../../"

  lambda_settings = {
    function_name = var.function_name
    description   = "This Lambda will list all Event-Rules and and EC2 instances and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime     = "python3.12"
      memory_size = 128
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
```

### Use-Case-3
In this Use-Case two Lambdas will share an IAM Role that is "externally" provided.

Location: [`./examples/use-case-3`](./examples/use-case-3/)
``` hcl
data "aws_caller_identity" "current" {}

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
        Sid = ""
      },
    ]
  })

  inline_policy {
    name   = "inline_lambda_execution_policy"
    policy = data.aws_iam_policy_document.lambda_permission.json
  }  
}

data "aws_iam_policy_document" "lambda_permission" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:DescribeLogGroups",
      "iam:ListRoles",
      "events:List*",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}


module "use_case_3_lambda1" {
  source = "../../"

  lambda_settings = {
    function_name = "${var.function_name}-1"
    description   = "This Lambda will list all CloudWatch LogGroups and IAM Roles and return them as JSON"
    handler       = "main.lambda_handler"
    config = {
      runtime     = "python3.12"
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
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url].

<!-- LICENSE -->
## License

See [LICENSE][license-url] for full details.

<!-- COPYRIGHT -->
<br />
<p align="center">Copyright &copy; 2024 ACAI GmbH</p>

<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.3.10-blue.svg?style=flat&color=blueviolet
[terraform-version-url]: https://www.terraform.io/upgrade-guides/1-3-10.html
[release-shield]: https://img.shields.io/github/v/release/acai-consulting/terraform-aws-acf-ou-mgmt?style=flat&color=success
[architecture-png]: ./docs/terraform-aws-acf-core-configuration.png
[license-url]: ./LICENSE
[terraform-url]: https://www.terraform.io
[aws-url]: https://aws.amazon.comterraform-aws-acf-ou-mgmt/tree/main/examples/complete
