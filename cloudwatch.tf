# ---------------------------------------------------------------------------------------------------------------------
# ¦ CLOUDWATCH SCHEDULE RULE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "schedule" {
  count = var.schedule_expression != null ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
}

resource "aws_cloudwatch_event_rule" "schedule" {
  count = var.schedule_expression != null ? 1 : 0

  name                = local.event_schedule_name
  description         = "schedule event rule for lambda ${local.lambda_name}"
  schedule_expression = var.schedule_expression
  tags                = var.resource_tags
}

resource "aws_cloudwatch_event_target" "schedule" {
  count = var.schedule_expression != null ? 1 : 0

  target_id = "attach_schedule_to_lambda"
  rule      = aws_cloudwatch_event_rule.schedule[0].name
  arn       = aws_lambda_function.this.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CLOUDWATCH PATTERN RULES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "pattern" {
  for_each = toset(var.event_patterns)

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pattern[each.key].arn
}

resource "aws_cloudwatch_event_rule" "pattern" {
  for_each = toset(var.event_patterns)

  name          = format("%s-pattern%s%s", var.function_name, index(var.event_patterns, each.value), local.suffix_k)
  description   = "pattern event rule for lambda ${local.lambda_name}"
  event_pattern = each.value
  tags          = var.resource_tags
}

resource "aws_cloudwatch_event_target" "pattern" {
  for_each = toset(var.event_patterns)

  target_id = "attach_schedule_to_lambda"
  rule      = aws_cloudwatch_event_rule.pattern[each.key].name
  arn       = aws_lambda_function.this.arn
}
