output "vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.this.arn
}

output "vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.this.name
}

output "backup_role_arn" {
  description = "ARN of the IAM role used by AWS Backup"
  value       = aws_iam_role.backup.arn
}

output "plan_arns" {
  description = "Map of backup plan ARNs"
  value       = { for k, v in aws_backup_plan.this : k => v.arn }
}

output "notification_topic_arn" {
  description = "ARN of the SNS topic for backup notifications"
  value       = aws_sns_topic.backup_notifications.arn
}
