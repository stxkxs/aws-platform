output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = try(aws_guardduty_detector.this[0].id, null)
}

output "securityhub_arn" {
  description = "Security Hub account ARN"
  value       = try(aws_securityhub_account.this[0].arn, null)
}

output "sns_topic_arn" {
  description = "Security alerts SNS topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}
