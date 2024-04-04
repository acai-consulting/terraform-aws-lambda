variable "lambda_settings" {
  description = "Settings for the Lambda function."
  type = object({
    function_name = string
    description   = string
    layer_names   = optional(list(string), null)
    handler       = string
    config = object({
      runtime                = string
      architecture           = optional(string, "x86_64")
      timeout                = optional(number, 30)
      memory_size            = optional(number, 512)
      ephemeral_storage_size = optional(number, 512)
      log_retention_in_days  = optional(number, 90)
    })
    package = object({
      type        = optional(string, "Zip")
      local_path  = optional(string, null)
      source_path = optional(string, null)
    })
    environment_variables          = optional(map(string), {})
    reserved_concurrent_executions = optional(number, -1)
    publish                        = optional(bool, false)
    tracing_mode                   = optional(string)
    file_system_config = optional(object({
      arn              = string
      local_mount_path = string
    }), null)
    image_config = optional(object({
      image_uri         = optional(string)
      command           = optional(list(string), null)
      entry_point       = optional(list(string), null)
      working_directory = optional(string, null)
    }), null)
    vpc_config = optional(object({
      security_group_ids = list(string)
      subnet_ids         = list(string)
    }), null)
  })

  # validation of var.lambda_settings.config
  validation {
    condition     = contains(["x86_64", "arm64"], var.lambda_settings.config.architecture)
    error_message = "Invalid architecture value. Must be either 'x86_64' or 'arm64'."
  }

  validation {
    condition     = var.lambda_settings.config.timeout >= 1 && var.lambda_settings.config.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
  validation {
    condition     = var.lambda_settings.config.memory_size >= 128 && var.lambda_settings.config.memory_size <= 10240 && var.lambda_settings.config.memory_size % 64 == 0
    error_message = "Memory size must be between 128 MB to 10,240 MB, in 64 MB increments."
  }

  validation {
    condition     = var.lambda_settings.config.ephemeral_storage_size >= 512 && var.lambda_settings.config.ephemeral_storage_size <= 10240
    error_message = "Ephemeral storage size must be between 512 MB to 10,240 MB."
  }

  validation {
    condition     = var.lambda_settings.config.log_retention_in_days == null || can(index([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.lambda_settings.config.log_retention_in_days))
    error_message = "Invalid log_retention_in_days value."
  }

  # validation of var.lambda_settings.package
  validation {
    condition     = contains(["Zip", "Image"], var.lambda_settings.package.type)
    error_message = "Invalid package type. Must be either 'Zip' or 'Image'."
  }

  validation {
    condition     = var.lambda_settings.tracing_mode == null || contains(["Active", "PassThrough"], var.lambda_settings.tracing_mode)
    error_message = "Invalid tracing_mode value."
  }

  validation {
    condition     = var.lambda_settings.file_system_config == null || can(regex("^arn:aws:elasticfilesystem:", var.lambda_settings.file_system_config.arn))
    error_message = "File system config ARN must start with 'arn:aws:elasticfilesystem:'."
  }


  validation {
    condition     = var.lambda_settings.package.type != "Image" || (var.lambda_settings.image_config != null && var.lambda_settings.image_config != null ? var.lambda_settings.image_config.image_uri != "" : true)
    error_message = "When package type is 'Image', image_uri must be specified."
  }

  validation {
    condition     = can(length(var.lambda_settings.vpc_config.security_group_ids)) && can(length(var.lambda_settings.vpc_config.subnet_ids)) ? (length(var.lambda_settings.vpc_config.security_group_ids) > 0 && length(var.lambda_settings.vpc_config.subnet_ids) > 0) : true
    error_message = "Both security_group_ids and subnet_ids must be provided for VPC configuration."
  }

}

variable "trigger_settings" {
  description = "Settings for the Lambda function's trigger settings, including permissions, SQS triggers, schedule expressions, and event rules."
  type = object({
    trigger_permissions = optional(list(object({
      principal  = string
      source_arn = string
    })), null)
    sqs = optional(object({
      access_policy_json_list = list(string)
      inbound_sns_topics = optional(list(object(
        {
          sns_arn            = string
          filter_policy_json = string
        }
      )), [])
    }), null)
    schedule_expression = string
    event_rules = optional(list(object({
      name           = string
      description    = optional(string, "")
      event_bus_name = optional(string, "default")
      event_pattern  = string
    })), null)
  })
  default = null

  validation {
    condition = var.trigger_settings.sqs == null ? true : length(var.trigger_settings.trigger_permissions) == 0 || alltrue([
      for p in var.trigger_settings.trigger_permissions : can(regex(".+\\.amazonaws\\.com$|^\\d{12}$", p.principal)) && can(regex("^arn:aws:.+|^any$", p.source_arn))
    ])
    error_message = "Invalid trigger_permissions configuration."
  }

  validation {
    condition     = var.trigger_settings.sqs == null ? true : var.trigger_settings.sqs.access_policy_json == null || can(jsondecode(var.trigger_settings.sqs.access_policy_json))
    error_message = "The SQS access policy JSON must be a valid JSON string."
  }

  validation {
    condition = var.trigger_settings.sqs == null ? true : length(var.trigger_settings.sqs.inbound_sns_topics) == 0 || alltrue([
      for p in var.trigger_settings.sqs.inbound_sns_topics : can(regex("^arn:aws:sns:", p))
    ])
    error_message = "Values for trigger_settings.sqs.inbound_sns_topics must contain SNS ARN, starting with \"arn:aws:sns:\"."
  }

  validation {
    condition = var.trigger_settings.schedule_expression == null || can(
      regex("^(rate\\([1-9]\\d*\\s+(minutes?|hours?|days?)\\))$", var.trigger_settings.schedule_expression)
      ) || can(
      regex("^cron\\((?:\\S+\\s+){5,6}\\S+\\)$", var.trigger_settings.schedule_expression)
    )
    error_message = "The schedule_expression must be either a valid rate expression (e.g., 'rate(5 minutes)') or a cron expression (e.g., 'cron(0 20 * * ? *)')."
  }

  validation {
    condition = length(var.trigger_settings.event_rules) == 0 ? true : alltrue([
      for event_rule in var.trigger_settings.event_rules : (
        can(jsondecode(event_rule.event_pattern)) ?
        can(jsondecode(event_rule.event_pattern).source) :
        false
      )
    ])
    error_message = "Values must be valid JSON and have \"source\" field set."
  }
}

variable "execution_iam_role_settings" {
  description = "Settings of the for Lambda execution IAM role."
  type = object({
    new_iam_role = optional(object({
      name                     = optional(string)
      path                     = optional(string, "/")
      permissions_boundary_arn = optional(string)
      permission_policy_arns   = optional(list(string), [])
    }), null)
    existing_iam_role_name = optional(string, null)
  })
  default = {
    new_iam_role = {
      path                   = "/"
      permission_policy_arns = []
    }
  }
  validation {
    condition = (
      (var.execution_iam_role_settings.new_iam_role != null && var.execution_iam_role_settings.existing_iam_role_name == null) ||
      (var.execution_iam_role_settings.new_iam_role == null && var.execution_iam_role_settings.existing_iam_role_name != null)
    )
    error_message = "Specify exactly one of 'new_role' or 'existing_iam_role_name'."
  }
}

variable "existing_kms_cmk_arn" {
  description = "KMS key ARN to be used to encrypt logs and sqs messages."
  type        = string
  default     = null
  validation {
    condition     = var.existing_kms_cmk_arn == null ? true : can(regex("^arn:aws:kms", var.existing_kms_cmk_arn))
    error_message = "Value must contain ARN, starting with \"arn:aws:kms\"."
  }
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
