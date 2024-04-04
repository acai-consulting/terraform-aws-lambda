variable "settings_new_execution_iam_role" {
  type = object({
    iam_role_name            = string
    iam_role_path            = optional(string, "/")
    permissions_boundary_arn = optional(string, null)
    permission_policy_arns   = optional(list(string), [])
  })
  default = null
}

variable "existing_execution_iam_role_name" {
  type    = string
  default = null
}

variable "runtime_configuration" {
  type = object({
    function_name       = string
    loggroup_name       = string
    trigger_sqs_enabled = bool
    trigger_sqs_arn     = optional(string, null)
    encryption_enabled  = bool
    kms_key_arn         = optional(string, null)
  })
}


variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
