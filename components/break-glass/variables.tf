variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "team" {
  description = "Owning team for this component"
  type        = string
}

variable "trusted_account_ids" {
  description = "AWS account IDs allowed to assume the break-glass role"
  type        = list(string)
}

variable "notification_emails" {
  description = "Email addresses for break-glass usage notifications"
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for break-glass role"
  type        = number
  default     = 3600
}

variable "enable_permissions_boundary" {
  description = "Enable permissions boundary on break-glass role"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
