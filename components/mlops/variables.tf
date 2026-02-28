variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_sg_id" {
  description = "EKS cluster security group ID"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_issuer" {
  description = "EKS OIDC issuer URL (without https://)"
  type        = string
}

variable "tenants" {
  description = "Map of MLOps tenant configurations"
  type = map(object({
    deletion_protection           = optional(bool, true)
    ecr_enabled                   = optional(bool, true)
    point_in_time_recovery        = optional(bool, true)
    datasets_lifecycle_ia_days    = optional(number, 90)
    datasets_version_expiry_days  = optional(number, 730)
    artifacts_lifecycle_ia_days   = optional(number, 90)
    artifacts_version_expiry_days = optional(number, 730)
    run_ttl_days                  = optional(number, 395)
    deprecated_version_ttl_days   = optional(number, 395)
    sqs_visibility_timeout        = optional(number, 900)
    sqs_max_receive_count         = optional(number, 3)
    sqs_dlq_retention_days        = optional(number, 14)
  }))
}

variable "team" {
  description = "Owning team for this component"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
