output "kms_key_arn" {
  description = "Compliance KMS key ARN"
  value       = aws_kms_key.compliance.arn
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = try(aws_cloudtrail.org[0].arn, null)
}

output "cloudtrail_bucket_name" {
  description = "CloudTrail S3 bucket name"
  value       = try(module.cloudtrail_bucket[0].s3_bucket_id, null)
}

output "config_recorder_id" {
  description = "Config recorder ID"
  value       = try(aws_config_configuration_recorder.this[0].id, null)
}

output "config_bucket_name" {
  description = "Config snapshots S3 bucket name"
  value       = try(module.config_bucket[0].s3_bucket_id, null)
}
