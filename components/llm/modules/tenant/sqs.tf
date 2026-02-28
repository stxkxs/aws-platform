resource "aws_sqs_queue" "inference_dlq" {
  name                      = "${local.prefix}-inference-dlq"
  message_retention_seconds = var.tenant_config.sqs_retention_days * 86400
  sqs_managed_sse_enabled   = true
  tags                      = local.tenant_tags
}

resource "aws_sqs_queue" "inference" {
  name                       = "${local.prefix}-inference"
  visibility_timeout_seconds = var.tenant_config.sqs_visibility_timeout
  message_retention_seconds  = var.tenant_config.sqs_retention_days * 86400
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.inference_dlq.arn
    maxReceiveCount     = var.tenant_config.sqs_max_receive_count
  })

  tags = local.tenant_tags
}
