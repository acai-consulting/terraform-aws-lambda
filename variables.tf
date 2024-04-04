variable "lambda" {
  type = object({
    function_name = string
    description   = string
    layer_names   = list(string)
    handler       = string
    config = object({
      runtime           = string                     #  Identifier of the function's runtime. See Runtimes for valid values.
      architecture      = optional(string, "x86_64") # Instruction set architecture for your Lambda function. Valid values are 'x86_64' and 'arm64'.
      timeout           = optional(number, 30)
      memory_size       = optional(number, 512)
      ephemeral_storage = optional(number, 512)

    })
    environment_variables = optional(map(string), {}) # Map of environment variables that are accessible from the function code during execution.
    package = object({
      type        = optional(string, "Zip")
      local_path  = optional(string, null)
      source_path = optional(string, null)
    })
    reserved_concurrent_executions = optional(number, -1)
    publish                        = optional(bool, false) # Whether to publish creation/change as new Lambda Function Version.
    vpc_config = optional({
      subnet_ids         = optional(list(string), [])
      security_group_ids = optional(list(string), [])
    }, null)
  })
}

variable "iam_execution_role" {
  type = object({
    name               = optional(string)
    access_policy_json = optional(string, null)
    timeout            = number
    inbound_sns_topics = list(string)
  })
  default = null
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
