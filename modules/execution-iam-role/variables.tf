variable "settings_new_execution_iam_role" {
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
  type    = string
  default = null
}

variable "runtime_configuration" {
  description = "Configuration related to the runtime environment of the Lambda function."
  type = object({
    function_name       = string
    loggroup_name       = string
    trigger_sqs_enabled = bool
    trigger_sqs_arn     = optional(string)
    encryption_enabled  = bool
    kms_key_arn         = optional(string)
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}