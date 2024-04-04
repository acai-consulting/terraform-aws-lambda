variable "execution_iam_role_settings" {
  description = "Configuration of the for Lambda execution IAM role."
  type = object({
    new_iam_role = optional(object({
      name                     = string
      path                     = string
      permissions_boundary_arn = string
      permission_policy_arns   = list(string)
    }), null)
    existing_iam_role_name = optional(string, null)
  })

  validation {
    condition = (
      (var.execution_iam_role_settings.new_role != null && var.execution_iam_role_settings.existing_role == null) ||
      (var.execution_iam_role_settings.new_role == null && var.execution_iam_role_settings.existing_role != null)
    )
    error_message = "Specify exactly one of 'new_role' or 'existing_role'."
  }
}

variable "runtime_configuration" {
  description = "Configuration related to the runtime environment of the Lambda function."
  type = object({
    function_name       = string
    loggroup_name       = string
    trigger_sqs_enabled = bool
    trigger_sqs_arn     = string
    encryption_enabled  = bool
    kms_key_arn         = string
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
