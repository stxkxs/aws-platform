variable "environment" {
  description = "Environment name"
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
  description = "Tenant configuration"
  type = object({
    deletion_protection           = bool
    msk_enabled                   = bool
    batch_enabled                 = bool
    step_functions_enabled        = bool
    schema_registry_enabled       = bool
    batch_max_vcpus               = number
    batch_type                    = string
    sfn_logging_level             = string
    raw_lifecycle_ia_days         = number
    raw_lifecycle_expiry_days     = number
    staging_lifecycle_expiry_days = number
    curated_version_expiry_days   = number
  })
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "EKS cluster security group ID"
  type        = string
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
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
