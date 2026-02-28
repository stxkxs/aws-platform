resource "aws_cloudwatch_event_bus" "this" {
  count = var.tenant_config.event_bridge_enabled ? 1 : 0
  name  = local.prefix
  tags  = local.tenant_tags
}

resource "aws_cloudwatch_event_archive" "this" {
  count            = var.tenant_config.event_bridge_enabled ? 1 : 0
  name             = "${local.prefix}-archive"
  event_source_arn = aws_cloudwatch_event_bus.this[0].arn
  retention_days   = var.tenant_config.archive_retention_days
}
