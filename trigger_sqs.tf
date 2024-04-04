locals {
    trigger_sqs_name = format(
      "%s-trigger%s",
      var.function_name,
      local.suffix_k
    )
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LAMBDA SQS TRIGGER (OPTIONAL)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_sqs_queue" "lambda_trigger" {
  count = var.trigger_sqs != null ? 1 : 0

  name                       = local.trigger_sqs_name
  kms_master_key_id          = var.kms_key_arn
  visibility_timeout_seconds = var.trigger_sqs.timeout
  tags                       = var.resource_tags
}

resource "aws_sqs_queue_policy" "lambda_trigger" {
  count = var.trigger_sqs != null ? 1 : 0

  queue_url = aws_sqs_queue.lambda_trigger[0].id
  policy    = data.aws_iam_policy_document.lambda_trigger_policy[0].json
}

data "aws_iam_policy_document" "lambda_trigger_policy" {
  count = var.trigger_sqs != null ? 1 : 0

  source_policy_documents = var.trigger_sqs.access_policy_json
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
    for_each = length(var.trigger_sqs.inbound_sns_topics) == 0 ? [] : ["add"]
    content {
      sid = "AllowInboundSns"
      actions = [
        "sqs:SendMessage"
      ]
      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
      resources = ["*"]
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values = [
          for item in var.trigger_sqs.inbound_sns_topics : item.sns_arn
        ]
      }
    }
  }
}

resource "aws_sns_topic_subscription" "lambda_trigger" {
  count = length(var.trigger_sqs.inbound_sns_topics)

  topic_arn     = element(var.trigger_sqs.inbound_sns_topics, count.index).sns_arn
  protocol      = "sqs"
  filter_policy = element(var.trigger_sqs.inbound_sns_topics, count.index).filter_policy_json
  endpoint      = aws_sqs_queue.lambda_trigger[0].arn
}

resource "aws_lambda_event_source_mapping" "lambda_trigger" {
  count = var.trigger_sqs != null ? 1 : 0

  event_source_arn = aws_sqs_queue.lambda_trigger[0].arn
  function_name    = aws_lambda_function.this.arn
}