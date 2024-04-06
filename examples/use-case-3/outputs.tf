output "use_case_3_lambda1" {
  value = module.use_case_3_lambda1
}

output "use_case_3_lambda1_result" {
  value = jsondecode(aws_lambda_invocation.use_case_3_lambda1.result)
}

output "use_case_3_lambda2" {
  value = module.use_case_3_lambda2
}

output "use_case_3_lambda2_result" {
  value = jsondecode(aws_lambda_invocation.use_case_3_lambda2.result)
}
