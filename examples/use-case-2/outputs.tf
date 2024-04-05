output "lambda_name" {
  value = module.use_case_2_lambda.lambda.name
}

output "lambda_arn" {
  value = module.use_case_2_lambda.lambda.arn
}

output "use_case_2_lambda" {
  value = module.use_case_2_lambda
}

output "use_case_2_lambda_result" {
  value = jsondecode(aws_lambda_invocation.use_case_2_lambda.result)
}
