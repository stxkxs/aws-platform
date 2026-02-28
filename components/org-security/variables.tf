variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "enable_guardduty" {
  description = "Enable GuardDuty detector"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable Security Hub"
  type        = bool
  default     = true
}

variable "guardduty_features" {
  description = "GuardDuty feature toggles"
  type = object({
    s3_protection           = optional(bool, true)
    eks_audit_logs          = optional(bool, true)
    eks_runtime_monitoring  = optional(bool, true)
    malware_protection      = optional(bool, true)
    rds_login_events        = optional(bool, false)
    lambda_network_activity = optional(bool, false)
  })
  default = {}
}

variable "member_accounts" {
  description = "Map of member accounts to enroll in GuardDuty and Security Hub"
  type = map(object({
    account_id = string
    email      = string
  }))
  default = {}
}

variable "securityhub_standards" {
  description = "List of Security Hub standards ARNs to enable"
  type        = list(string)
  default = [
    "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/3.0.0",
    "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0",
  ]
}

variable "enable_cross_region_aggregation" {
  description = "Enable Security Hub cross-region finding aggregation"
  type        = bool
  default     = false
}

variable "alert_email_endpoints" {
  description = "Email addresses for security alert notifications"
  type        = list(string)
  default     = []
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
