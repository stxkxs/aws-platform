variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tenant_id" {
  description = "Tenant identifier"
  type        = string
}

variable "tenant_config" {
  description = "Tenant governance configuration"
  type = object({
    deletion_protection    = optional(bool, true)
    object_lock_enabled    = optional(bool, false)
    event_bridge_enabled   = optional(bool, true)
    point_in_time_recovery = optional(bool, true)
    lifecycle_ia_days      = optional(number, 90)
    lifecycle_glacier_days = optional(number, 365)
    archive_retention_days = optional(number, 90)
    cost_ttl_days          = optional(number, 395)
  })
}

variable "oidc_provider" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_issuer" {
  description = "EKS OIDC issuer URL (without https://)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
