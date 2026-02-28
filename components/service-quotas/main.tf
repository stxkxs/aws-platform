locals {
  tags = merge(var.tags, {
    Component = "service-quotas"
    Team      = var.team
  })
}

################################################################################
# Quota Lookup
################################################################################

data "aws_servicequotas_service_quota" "this" {
  for_each = var.monitored_quotas

  service_code = each.value.service_code
  quota_code   = each.value.quota_code
}

################################################################################
# SNS Topic for Alerts
################################################################################

resource "aws_sns_topic" "quota_alerts" {
  name = "${var.environment}-service-quota-alerts"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "quota_email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.quota_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

################################################################################
# CloudWatch Alarms for Quota Utilization
################################################################################

resource "aws_cloudwatch_metric_alarm" "quota" {
  for_each = var.monitored_quotas

  alarm_name          = "${var.environment}-quota-${each.key}"
  alarm_description   = "Service quota alarm: ${each.value.description} exceeds ${var.quota_threshold_percent}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = data.aws_servicequotas_service_quota.this[each.key].value * var.quota_threshold_percent / 100

  metric_name = "ResourceCount"
  namespace   = "AWS/Usage"
  period      = 300
  statistic   = "Maximum"

  dimensions = {
    Type     = "Resource"
    Service  = each.value.service_code
    Resource = each.value.quota_code
    Class    = "None"
  }

  alarm_actions = [aws_sns_topic.quota_alerts.arn]

  tags = local.tags
}

################################################################################
# SSM Parameters
################################################################################

resource "aws_ssm_parameter" "quota_topic_arn" {
  name  = "/${var.environment}/service-quotas/alert-topic-arn"
  type  = "String"
  value = aws_sns_topic.quota_alerts.arn

  tags = local.tags
}
