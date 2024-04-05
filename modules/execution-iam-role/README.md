<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.00 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.00 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_context](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.new_lambda_permission_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.execution_role_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_context](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.new_lambda_permission_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.existing_execution_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_execution_iam_role_settings"></a> [execution\_iam\_role\_settings](#input\_execution\_iam\_role\_settings) | Configuration of the for Lambda execution IAM role. | <pre>object({<br>    new_iam_role = optional(object({<br>      name                        = string<br>      path                        = string<br>      permissions_boundary_arn    = string<br>      permission_policy_arn_list  = list(string)<br>      permission_policy_json_list = list(string)<br>    }), null)<br>    existing_iam_role_name = optional(string, null)<br>  })</pre> | n/a | yes |
| <a name="input_runtime_configuration"></a> [runtime\_configuration](#input\_runtime\_configuration) | Configuration related to the runtime environment of the Lambda function. | <pre>object({<br>    lambda_name   = string<br>    loggroup_name = string<br>  })</pre> | n/a | yes |
| <a name="input_existing_kms_cmk_arn"></a> [existing\_kms\_cmk\_arn](#input\_existing\_kms\_cmk\_arn) | KMS key ARN to be used to encrypt logs and sqs messages. | `string` | `null` | no |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_execution_iam_role"></a> [lambda\_execution\_iam\_role](#output\_lambda\_execution\_iam\_role) | Information about the Lambda execution role. |
<!-- END_TF_DOCS -->