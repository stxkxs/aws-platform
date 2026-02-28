output "budget_name" {
  description = "The name of the org monthly budget"
  value       = aws_budgets_budget.org_monthly.name
}

output "budget_id" {
  description = "The ID of the org monthly budget"
  value       = aws_budgets_budget.org_monthly.id
}

output "anomaly_monitor_service_arn" {
  description = "Cost anomaly monitor (by service) ARN"
  value       = try(aws_ce_anomaly_monitor.service[0].arn, null)
}

output "anomaly_monitor_account_arn" {
  description = "Cost anomaly monitor (by linked account) ARN"
  value       = try(aws_ce_anomaly_monitor.linked_account[0].arn, null)
}

output "anomaly_subscription_arn" {
  description = "Cost anomaly subscription ARN"
  value       = try(aws_ce_anomaly_subscription.this[0].arn, null)
}

output "cur_export_bucket_name" {
  description = "CUR 2.0 export S3 bucket name"
  value       = try(module.cur_bucket[0].s3_bucket_id, null)
}

output "cost_category_arns" {
  description = "Map of cost category name to ARN"
  value = {
    for k, v in aws_ce_cost_category.this : k => v.arn
  }
}
