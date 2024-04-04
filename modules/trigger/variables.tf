variable "trigger_settings" {
  type = object({
    sqs = optional(object({
      access_policy_json = string
      timeout            = number
      inbound_sns_topics = list(string)
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
    function_name = string
    function_arn  = string
  })
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}
