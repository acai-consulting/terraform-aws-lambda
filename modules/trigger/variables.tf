variable "trigger_settings" {
  type = object({
    trigger_permissions = optional(list(object({
      principal  = string
      source_arn = string
      source_account = string
    })), null)
    sqs = optional(object({
      access_policy_json_list = optional(list(string), [])
      inbound_sns_topics = optional(list(object(
        {
          sns_arn            = string
          filter_policy_json = optional(string, null)
        }
      )), [])
    }), null)
    schedule_expression = string
    event_rules = optional(list(object({
      name           = string
      description    = string
      event_bus_name = string
      event_pattern  = string
    })), null)
  })
}

variable "existing_kms_cmk_arn" {
  description = "KMS key ARN to be used to encrypt logs and sqs messages."
  type        = string
  default     = null
}

variable "runtime_configuration" {
  description = "Configuration related to the runtime environment of the Lambda function."
  type = object({
    lambda_name    = string
    lambda_arn     = string
    lambda_timeout = number

  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
