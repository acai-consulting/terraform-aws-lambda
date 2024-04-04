# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.00"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  region_name_splitted = split("-", data.aws_region.current.name)
  region_name_short    = "${local.region_name_splitted[0]}${substr(local.region_name_splitted[1], 0, 1)}${local.region_name_splitted[2]}"

  trigger_sqs_name        = "${var.runtime_configuration.function_name}-trigger"
  schedule_eventrule_name = "${var.runtime_configuration.function_name}-schedule"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ SQS TRIGGER (OPTIONAL)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_sqs_queue" "lambda_trigger" {
  count = var.trigger_settings.sqs != null ? 1 : 0

  name                       = local.trigger_sqs_name
  kms_master_key_id          = var.existing_kms_cmk_arn
  visibility_timeout_seconds = var.trigger_settings.sqs.timeout
  tags                       = var.resource_tags
}

resource "aws_sqs_queue_policy" "lambda_trigger" {
  count = var.trigger_settings.sqs != null ? 1 : 0

  queue_url = aws_sqs_queue.lambda_trigger[0].id
  policy    = data.aws_iam_policy_document.lambda_trigger_policy[0].json
}

data "aws_iam_policy_document" "lambda_trigger_policy" {
  count = var.trigger_settings.sqs != null ? 1 : 0

  source_policy_documents = var.trigger_settings.sqs.access_policy_json
  statement {
    sid     = "EnableIamUserPermissions"
    actions = ["sqs:*"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)]
    }
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.trigger_settings.sqs.inbound_sns_topics) != 0 ? [1] : []
    content {
      sid     = "AllowInboundSns"
      actions = ["sqs:SendMessage"]
      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
      resources = ["*"]
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values = [
          for item in var.trigger_settings.sqs.inbound_sns_topics : item.sns_arn
        ]
      }
    }
  }
}

resource "aws_sns_topic_subscription" "lambda_trigger" {
  count = length(var.trigger_settings.sqs.inbound_sns_topics)

  topic_arn     = element(var.trigger_settings.sqs.inbound_sns_topics, count.index).sns_arn
  protocol      = "sqs"
  filter_policy = element(var.trigger_settings.sqs.inbound_sns_topics, count.index).filter_policy_json
  endpoint      = aws_sqs_queue.lambda_trigger[0].arn
}

resource "aws_lambda_event_source_mapping" "lambda_trigger" {
  count = var.trigger_settings.sqs != null ? 1 : 0

  event_source_arn = aws_sqs_queue.lambda_trigger[0].arn
  function_name    = var.runtime_configuration.function_name
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CLOUDWATCH SCHEDULE RULE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "schedule" {
  count = var.trigger_settings.schedule_expression != null ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = var.runtime_configuration.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
}

resource "aws_cloudwatch_event_rule" "schedule" {
  count = var.trigger_settings.schedule_expression != null ? 1 : 0

  name                = var.trigger_settings.schedule.name
  description         = "Schedule event rule for lambda ${var.runtime_configuration.function_name}"
  schedule_expression = var.trigger_settings.schedule_expression
  tags                = var.resource_tags
}

resource "aws_cloudwatch_event_target" "schedule" {
  count = var.trigger_settings.schedule_expression != null ? 1 : 0

  target_id = "attach_schedule_to_lambda"
  rule      = aws_cloudwatch_event_rule.schedule[0].name
  arn       = var.runtime_configuration.function_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CLOUDWATCH PATTERN RULES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "pattern" {
  for_each = toset(try(var.trigger_settings.event_rules, []))

  action        = "lambda:InvokeFunction"
  function_name = var.runtime_configuration.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pattern[each.key].arn
}

resource "aws_cloudwatch_event_rule" "pattern" {
  for_each = toset(try(var.trigger_settings.event_rules, []))

  name           = each.value.name
  description    = "pattern event rule for lambda ${var.runtime_configuration.function_name}"
  event_pattern  = each.value.event_pattern
  event_bus_name = each.value.event_bus_name
  tags           = var.resource_tags
}

resource "aws_cloudwatch_event_target" "pattern" {
  for_each = toset(try(var.trigger_settings.event_rules, []))

  target_id = "attach_schedule_to_lambda"
  rule      = aws_cloudwatch_event_rule.pattern[each.key].name
  arn       = var.runtime_configuration.function_arn
}
