output "lambda_name" {
  value = module.test_lambda.lambda.name
}

output "lambda_arn" {
  value = module.test_lambda.lambda.arn
}


output "test_lambda" {
  value = module.test_lambda
}

