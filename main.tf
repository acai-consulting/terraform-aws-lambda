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
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0"
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
  region_name_length = length(data.aws_region.current.name)
  region_name_short = format("%s%s%s",
    substr(data.aws_region.current.name, 0, 2),
    substr(data.aws_region.current.name, 3, 1),                           // Assuming you want the character at index 3 (fourth character)
    substr(data.aws_region.current.name, local.region_name_length - 1, 1) // Get the last character
  )
  trigger_sqs_name = "${aws_lambda_function.this.function_name}-trigger"
  loggroup_name    = "/aws/lambda/${var.lambda_settings.function_name}"
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
data "archive_file" "lambda_package" {
  count = var.lambda_settings.package.source_path == null ? 0 : 1

  type        = "zip"
  source_dir  = var.lambda_settings.package.source_path
  output_path = "${path.module}/${local.region_name_short}_zipped_package.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda_settings.function_name
  description   = var.lambda_settings.description
  layers        = var.lambda_settings.layer_names
  role          = module.lambda_execution_iam_role.lambda_execution_iam_role.arn
  handler       = var.lambda_settings.handler

  runtime       = var.lambda_settings.config.runtime
  architectures = [var.lambda_settings.config.architecture]
  timeout       = var.lambda_settings.config.timeout
  memory_size   = var.lambda_settings.config.memory_size

  ephemeral_storage {
    size = var.lambda_settings.config.ephemeral_storage_size
  }

  package_type     = var.lambda_settings.package.type
  image_uri        = try(var.lambda_settings.image_config.image_uri, null)
  filename         = var.lambda_settings.package.source_path == null ? var.lambda_settings.package.local_path : data.archive_file.lambda_package[0].output_path
  source_code_hash = var.lambda_settings.package.source_path == null ? filebase64sha256(var.lambda_settings.package.local_path) : data.archive_file.lambda_package[0].output_base64sha256

  environment {
    variables = var.lambda_settings.environment_variables
  }

  reserved_concurrent_executions = var.lambda_settings.reserved_concurrent_executions
  publish                        = var.lambda_settings.publish

  dynamic "tracing_config" {
    for_each = var.lambda_settings.tracing_mode != null ? [1] : []
    content {
      mode = var.lambda_settings.tracing_mode
    }
  }

  dynamic "file_system_config" {
    for_each = var.lambda_settings.file_system_config != null ? [1] : []
    content {
      arn              = var.lambda_settings.file_system_config.arn
      local_mount_path = var.lambda_settings.file_system_config.local_mount_path
    }
  }

  dynamic "image_config" {
    for_each = var.lambda_settings.image_config != null ? [1] : []
    content {
      command           = var.lambda_settings.image_config.command
      entry_point       = var.lambda_settings.image_config.entry_point
      working_directory = var.lambda_settings.image_config.working_directory
    }
  }

  dynamic "vpc_config" {
    for_each = var.lambda_settings.vpc_config != null ? [1] : []
    content {
      security_group_ids = var.lambda_settings.vpc_config.security_group_ids
      subnet_ids         = var.lambda_settings.vpc_config.subnet_ids
    }
  }

  tags = var.resource_tags

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    module.lambda_execution_iam_role
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CLOUDWATCH LOGS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = local.loggroup_name
  retention_in_days = var.lambda_settings.config.log_retention_in_days
  kms_key_id        = var.existing_kms_cmk_arn
  tags              = var.resource_tags
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ TRIGGER
# ---------------------------------------------------------------------------------------------------------------------
module "lambda_trigger" {
  source = "./modules/trigger"
  count  = var.trigger_settings != {} ? 1 : 0

  trigger_settings     = var.trigger_settings
  existing_kms_cmk_arn = var.existing_kms_cmk_arn
  runtime_configuration = {
    lambda_name    = aws_lambda_function.this.function_name
    lambda_arn     = aws_lambda_function.this.arn
    lambda_timeout = aws_lambda_function.this.timeout
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM EXECUTION ROLE
# ---------------------------------------------------------------------------------------------------------------------
module "lambda_execution_iam_role" {
  source = "./modules/execution-iam-role"

  execution_iam_role_settings = var.execution_iam_role_settings
  existing_kms_cmk_arn = var.existing_kms_cmk_arn
  runtime_configuration = {
    lambda_name   = var.lambda_settings.function_name
    loggroup_name = local.loggroup_name
  }
}

resource "aws_iam_role_policy_attachment" "aws_xray_write_only_access" {
  count      = var.lambda_settings.tracing_mode == null ? 0 : 1
  role       = module.lambda_execution_iam_role.lambda_execution_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy" "triggering_sqs_permissions" {
  count  = var.trigger_settings.sqs != null ? 1 : 0
  name   = "TriggeringSqsPermissions"
  role   = module.lambda_execution_iam_role.lambda_execution_iam_role.name
  policy = data.aws_iam_policy_document.triggering_sqs_permissions.json
}

data "aws_iam_policy_document" "triggering_sqs_permissions" {
  dynamic "statement" {
    for_each = var.trigger_settings.sqs != null ? [1] : []
    content {
      sid       = "AllowTriggerSqs"
      effect    = "Allow"
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      resources = [module.lambda_trigger[0].trigger_sqs_arn]
    }
  }
}
