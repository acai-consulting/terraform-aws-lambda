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
  function_name                  = local.lambda_name
  description                    = var.lambda.description
  layers                         = var.lambda.layer_names
  role                           = module.execution_role.lambda_execution_role_arn
  handler                        = var.lambda.handler

  runtime                        = var.lambda.config.runtime
  architectures                  = [var.lambda.config.architecture]
  timeout                        = var.lambda.config.timeout
  memory_size                    = var.lambda.config.memory_size

  ephemeral_storage              {
    size = var.lambda.config.ephemeral_storage # Min 512 MB and the Max 10240 MB
  } 
  package_type                   = var.lambda.package.type
  filename                       = var.lambda.package.source_path == null ? var.lambda.package.local_path : data.archive_file.lambda_package[0].output_path
  source_code_hash               = var.lambda.package.source_path == null ? filebase64sha256(var.lambda.package.local_path) : data.archive_file.lambda_package[0].output_base64sha256
  reserved_concurrent_executions = var.reserved_concurrent_executions
  publish                        = var.lambda.publish

  dynamic "environment" {
    # add environment when environment_variables are defined
    for_each = length(keys(var.lambda.environment_variables)) == 0 ? [] : [true]
    content {
      variables = var.lambda.environment_variables
    }
  }

  dynamic "vpc_config" {
    # add vpc_config when vpc_subnet_ids and vpc_security_group_ids are defined
    for_each = var.vpc_subnet_ids == null && var.vpc_security_group_ids == null ? [] : [true]
    iterator = filter
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  dynamic "tracing_config" {
    # add tracing_config when tracing_mode is defined
    for_each = var.tracing_mode == null ? [] : [true]
    content {
      mode = var.tracing_mode
    }
  }

  dynamic "file_system_config" {
    # add file_system_config when file_system_config_arn and file_system_config_local_mount_path are defined
    for_each = var.file_system_config_arn == null && var.file_system_config_local_mount_path == null ? [] : [true]
    content {
      local_mount_path = var.file_system_config_local_mount_path
      arn              = var.file_system_config_arn
    }
  }

  tags                           = var.resource_tags

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
    for k, v in var.trigger_permissions : k => v
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

  function_name = local.lambda_name
  # if the iam execution role should not be created an external iam execution role arn is expected instead
  create_execution_role                       = var.create_execution_role
  iam_execution_role_external_name            = var.iam_execution_role_external_name
  iam_execution_role_name                     = var.iam_execution_role_name == null ? local.execution_role_name : var.iam_execution_role_name
  iam_execution_role_path                     = var.iam_execution_role_path
  iam_execution_role_permissions_boundary_arn = var.iam_execution_role_permissions_boundary_arn
  iam_execution_policy_arns                   = var.iam_execution_policy_arns
  trigger_sqs_enabled                         = var.trigger_sqs_enabled
  trigger_sqs_arn                             = var.trigger_sqs_enabled == true ? aws_sqs_queue.lambda_trigger[0].arn : ""
  lambda_loggroup_name                        = aws_cloudwatch_log_group.lambda_logs.name
  resource_tags                               = var.resource_tags
  resource_name_suffix                        = var.resource_name_suffix
  enable_tracing                              = var.tracing_mode == null ? false : true
  enable_encryption                           = var.enable_encryption
  kms_key_arn                                 = var.kms_key_arn
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
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.kms_key_arn
  tags              = var.resource_tags
}