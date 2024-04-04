variable "lambda" {
  type = object({
    function_name = string
    description   = string
    layer_names   = list(string)
    handler       = string
    config = object({
      runtime                = string
      architecture           = optional(string, "x86_64")
      timeout                = optional(number, 30)
      memory_size            = optional(number, 512)
      ephemeral_storage_size = optional(number, 512)
      log_retention_in_days  = optional(number, null)
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
    trigger_permissions = optional(list(object({
      principal  = string
      source_arn = string
    })), null)
  })

  validation {
    condition     = var.lambda.config.log_retention_in_days == null || can(index([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.lambda.config.log_retention_in_days))
    error_message = "Invalid log_retention_in_days value."
  }

  validation {
    condition     = var.lambda.tracing_mode == null || contains(["Active", "PassThrough"], var.lambda.tracing_mode)
    error_message = "Invalid tracing_mode value."
  }

  validation {
    condition = length(var.lambda.trigger_permissions) == 0 || alltrue([
      for p in var.lambda.trigger_permissions : can(regex(".+\\.amazonaws\\.com$|^\\d{12}$", p.principal)) && can(regex("^arn:aws:.+|^any$", p.source_arn))
    ])
    error_message = "Invalid trigger_permissions configuration."
  }
}

variable "execution_iam_role_settings" {
  description = "Configuration of the for Lambda execution IAM role."
  type = object({
    new_role = optional(object({
      iam_role_name            = string
      iam_role_path            = optional(string, "/")
      permissions_boundary_arn = optional(string)
      permission_policy_arns   = optional(list(string), [])
    }), null)
    existing_role = optional(object({
      iam_role_name = string
    }), null)
  })

  validation {
    condition = (
      (var.execution_iam_role_settings.new_role != null && var.execution_iam_role_settings.existing_role == null) ||
      (var.execution_iam_role_settings.new_role == null && var.execution_iam_role_settings.existing_role != null)
    )
    error_message = "Specify exactly one of 'new_role' or 'existing_role'."
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

variable "trigger_context" {
  type = object({
    sqs = optional(object({
      access_policy_json = optional(string, null)
      timeout            = number
      inbound_sns_topics = list(string)
    }), null)
    scheduling = optional(object({
      name               = string
      access_policy_json = optional(string, null)
      timeout            = number
      inbound_sns_topics = list(string)
    }), null)
    event_rules = optional(list(object({
      name           = string
      description    = string
      event_bus_name = optional(string, "default")
      event_pattern  = string
    })), null)
  })
  default = null

  validation {
    condition = length(var.trigger_context.event_rules) == 0 ? true : alltrue([
      for pattern in var.trigger_context.event_rules : (
        can(jsondecode(pattern)) ?
        can(jsondecode(pattern).source) :
        false
      )
    ])
    error_message = "Values must be valid JSON and have \"source\" field set."
  }
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
