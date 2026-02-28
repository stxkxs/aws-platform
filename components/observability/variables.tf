variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name (for CloudWatch metrics)"
  type        = string
}

variable "alert_email_endpoints" {
  description = "Email addresses for SNS alerts"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts (stored in SNS -> Lambda or Chatbot)"
  type        = string
  default     = ""
}

variable "enable_cluster_alarms" {
  description = "Enable EKS CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_dashboard" {
  description = "Enable CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "alarm_config" {
  description = "Alarm thresholds configuration"
  type = object({
    cpu_utilization_threshold    = number
    memory_utilization_threshold = number
    node_not_ready_period        = number
    api_server_error_threshold   = number
    api_server_latency_threshold = number
  })
  default = {
    cpu_utilization_threshold    = 80
    memory_utilization_threshold = 80
    node_not_ready_period        = 300
    api_server_error_threshold   = 5
    api_server_latency_threshold = 3000
  }
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
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
