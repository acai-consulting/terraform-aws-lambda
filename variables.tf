variable "lambda" {
  type = object({
    function_name = string
    description   = string
    layer_names   = list(string)
    handler       = string
    config = object({
      runtime                = string                     #  Identifier of the function's runtime. See Runtimes for valid values.
      architecture           = optional(string, "x86_64") # Instruction set architecture for your Lambda function. Valid values are 'x86_64' and 'arm64'.
      timeout                = optional(number, 30)
      memory_size            = optional(number, 512)
      ephemeral_storage_size = optional(number, 512) # Min 512 MB and the Max 10240 MB
      log_retention_in_days  = optional(number, null)
    })
    package = object({
      type        = optional(string, "Zip")
      local_path  = optional(string, null)
      source_path = optional(string, null)
    })
    environment_variables          = optional(map(string), {}) # Map of environment variables that are accessible from the function code during execution.
    reserved_concurrent_executions = optional(number, -1)
    publish                        = optional(bool, false) # Whether to publish creation/change as new Lambda Function Version.
    tracing_mode                   = optional(string)
    file_system_config = optional(object({
      arn              = string
      local_mount_path = string
   }), null)
    image_config = optional(object({
      image_uri         = optional(string)
      command           = optional(string, null)
      entry_point       = optional(string, null)
      working_directory = optional(string, null)
   }), null)
    vpc_config = optional(object({
      security_group_ids = optional(list(string), [])
      subnet_ids         = optional(list(string), [])
   }), null)
    trigger_permissions = optional(list(object( # Tuple of principals to grant lambda-trigger permission.
      {
        principal  = string # The principal who is getting trigger permission. e.g. s3.amazonaws.com, any valid AWS service principal or an AWS account ID.
        source_arn = string # The ARN of the specific resource within that service to grant permission to. Set to 'any' to grant permission to any resource in principal.
    })), null)
  })

  validation {
    condition     = var.lambda.config.log_retention_in_days == null ? true : contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.lambda.config.log_retention_in_days)
    error_message = "Value must be one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0."
  }
  validation {
    condition     = var.lambda.tracing_mode == null ? true : contains(["Active", "PassThrough"], var.lambda.tracing_mode)
    error_message = "Value must be 'Active' or 'PassThrough'."
  }
  validation {
    condition = length(var.lambda.trigger_permissions) == 0 ? true : alltrue([
      for p in var.lambda.trigger_permissions : can(regex(".amazonaws.com$|^\\d{12}$", p.principal)) && can(regex("^arn:aws:|^any$", p.source_arn))
    ])
    error_message = "Values must contain Principals, ending with \".amazonaws.com\" or matching exactly 12 digits and Source ARNs, starting with \"arn:aws\" or matching exactly \"any\"."
  }
}

variable "new_execution_iam_role_settings" {
  description = "Configuration for creating a new IAM role for Lambda execution. Set to null to use an existing role."
  type = object({
    iam_role_name            = string
    iam_role_path            = optional(string, "/")
    permissions_boundary_arn = optional(string)
    permission_policy_arns   = optional(list(string), [])
  })
  default = null
}

variable "existing_execution_iam_role_name" {
  description = "The name of an existing IAM role for Lambda execution to be used if creating a new role is not required."
  type        = string
  default     = null
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

variable "scheduling" {
  type = object({
    name               = optional(string)
    access_policy_json = optional(string, null)
    timeout            = number
    inbound_sns_topics = list(string)
  })
  default = null
}

variable "trigger_sqs" {
  type = object({
    name               = optional(string)
    access_policy_json = optional(string, null)
    timeout            = number
    inbound_sns_topics = list(string)
  })
  default = null
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
