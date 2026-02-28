################################################################################
# SQS Training Queue + Dead-Letter Queue
################################################################################

resource "aws_sqs_queue" "training_dlq" {
  name                      = "${local.prefix}-training-dlq"
  message_retention_seconds = var.tenant_config.sqs_dlq_retention_days * 86400

  sqs_managed_sse_enabled = true

  tags = local.tenant_tags
}

resource "aws_sqs_queue" "training" {
  name                       = "${local.prefix}-training"
  visibility_timeout_seconds = var.tenant_config.sqs_visibility_timeout

  sqs_managed_sse_enabled = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.training_dlq.arn
    maxReceiveCount     = var.tenant_config.sqs_max_receive_count
  })

  tags = local.tenant_tags
}
