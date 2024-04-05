variable "function_name" {
  description = "Unique name for your Lambda Function."
  type        = string
  default     = "use_case_1"
}

variable "resource_tags" {
  type = map(string)
  default = {
    scope = "use_case_1"
  }
}
