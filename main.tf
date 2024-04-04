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
  region_name_splitted = split("-", data.aws_region.current.name)
  region_name_short    = "${local.region_name_splitted[0]}${substr(local.region_name_splitted[1], 0, 1)}${local.region_name_splitted[2]}"

  loggroup_name = "/aws/lambda/${ var.lambda.function_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
data "archive_file" "lambda_package" {
  count = var.lambda.package.source_path == null ? 0 : 1

  type        = "zip"
  source_dir  = var.lambda.package.source_path
  output_path = "${path.module}/${local.region_name_short}_zipped_package.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda.function_name
  description   = var.lambda.description
  layers        = var.lambda.layer_names
  role          = module.execution_role.lambda_execution_role_arn
  handler       = var.lambda.handler

  runtime       = var.lambda.config.runtime
  architectures = [var.lambda.config.architecture]
  timeout       = var.lambda.config.timeout
  memory_size   = var.lambda.config.memory_size

  ephemeral_storage {
    size = var.lambda.config.ephemeral_storage_size
  }

  package_type     = var.lambda.package.type
  image_uri        = var.lambda.image_config.image_uri
  filename         = var.lambda.package.source_path == null ? var.lambda.package.local_path : data.archive_file.lambda_package[0].output_path
  source_code_hash = var.lambda.package.source_path == null ? filebase64sha256(var.lambda.package.local_path) : data.archive_file.lambda_package[0].output_base64sha256

  environment {
    variables = var.lambda.environment_variables
  }

  reserved_concurrent_executions = var.lambda.reserved_concurrent_executions
  publish                        = var.lambda.publish

  dynamic "tracing_config" {
    for_each = var.lambda.tracing_mode != null ? [1] : []
    content {
      mode = var.lambda.tracing_mode
    }
  }

  dynamic "file_system_config" {
    for_each = var.lambda.file_system_config != null ? [1] : []
    content {
      arn              = var.lambda.file_system_config.arn
      local_mount_path = var.lambda.file_system_config.local_mount_path
    }
  }

  dynamic "image_config" {
    for_each = var.lambda.image_config != null ? [1] : []
    content {
      command           = var.lambda.image_config.command
      entry_point       = var.lambda.image_config.entry_point
      working_directory = var.lambda.image_config.working_directory
    }
  }

  dynamic "vpc_config" {
    for_each = var.lambda.vpc_config != null ? [1] : []
    content {
      security_group_ids = var.lambda.vpc_config.security_group_ids
      subnet_ids         = var.lambda.vpc_config.subnet_ids
    }
  }

  tags = var.resource_tags

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    module.execution_role
  ]
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA TRIGGERS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "allowed_triggers" {
  for_each = {
    for k, v in var.lambda.trigger_permissions : k => v
  }

  statement_id  = format("AllowExecution%02d", each.key)
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = each.value.principal
  # omit source_arn when 'any' to grant permission to any resource in principal
  source_arn = each.value.source_arn == "any" ? null : each.value.source_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM EXECUTION ROLE
# ---------------------------------------------------------------------------------------------------------------------
module "lambda_execution_iam_role" {
  source = "./modules/execution-role"

  new_execution_iam_role_settings  = var.new_execution_iam_role_settings
  existing_execution_iam_role_name = var.existing_execution_iam_role_name

  runtime_configuration = {
    function_name       = aws_lambda_function.this.function_name
    loggroup_name       = local.loggroup_name
    trigger_sqs_enabled = var.trigger_sqs != null
    trigger_sqs_arn     = var.trigger_sqs != null ? aws_sqs_queue.lambda_trigger[0].arn : null
    kms_key_arn         = var.existing_kms_cmk_arn
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ X-RAY - IAM POLICY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "aws_xray_write_only_access" {
  count      = var.lambda.enable_tracing == true ? 1 : 0
  role       = module.lambda_execution_iam_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CLOUDWATCH LOGS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = local.loggroup_name
  retention_in_days = var.lambda.config.log_retention_in_days
  kms_key_id        = var.existing_kms_cmk_arn
  tags              = var.resource_tags
}
