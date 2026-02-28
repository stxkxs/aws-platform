output "sns_topic_arn" {
  description = "ARN of the SNS topic for quota alerts"
  value       = aws_sns_topic.quota_alerts.arn
}

output "alarm_arns" {
  description = "Map of CloudWatch alarm ARNs for quota monitoring"
  value       = { for k, v in aws_cloudwatch_metric_alarm.quota : k => v.arn }
}

output "current_quotas" {
  description = "Map of current service quota values"
  value       = { for k, v in data.aws_servicequotas_service_quota.this : k => v.value }
}
