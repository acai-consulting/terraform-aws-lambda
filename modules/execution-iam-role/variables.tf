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
}

variable "runtime_configuration" {
  description = "Configuration related to the runtime environment of the Lambda function."
  type = object({
    lambda_name   = string
    loggroup_name = string
  })
}

variable "existing_kms_cmk_arn" {
  description = "KMS key ARN to be used to encrypt logs and sqs messages."
  type        = string
  default     = null
}

variable "resource_tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
