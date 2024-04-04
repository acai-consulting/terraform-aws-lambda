variable "resource_tags" {
  type = map(string)
  default = {
    Name = "test-kms-cmk"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA
# ---------------------------------------------------------------------------------------------------------------------
variable "function_name" {
  description = "Unique name for your Lambda Function."
  type        = string
}

variable "description" {
  description = "Description of what your Lambda Function does."
  type        = string
  default     = ""
}
