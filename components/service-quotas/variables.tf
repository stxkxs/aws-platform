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

variable "notification_emails" {
  description = "Email addresses for quota alert notifications"
  type        = list(string)
  default     = []
}

variable "quota_threshold_percent" {
  description = "Percentage threshold for quota alarms (0-100)"
  type        = number
  default     = 80
}

variable "monitored_quotas" {
  description = "Map of service quotas to monitor"
  type = map(object({
    service_code = string
    quota_code   = string
    description  = string
  }))
  default = {
    vpc_per_region = {
      service_code = "vpc"
      quota_code   = "L-F678F1CE"
      description  = "VPCs per region"
    }
    eips_per_region = {
      service_code = "ec2"
      quota_code   = "L-0263D0A3"
      description  = "Elastic IPs per region"
    }
    nat_gateways_per_az = {
      service_code = "vpc"
      quota_code   = "L-FE5A380F"
      description  = "NAT Gateways per AZ"
    }
    eks_clusters = {
      service_code = "eks"
      quota_code   = "L-1194D53C"
      description  = "EKS clusters per region"
    }
    lambda_concurrent = {
      service_code = "lambda"
      quota_code   = "L-B99A9384"
      description  = "Lambda concurrent executions"
    }
  }
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
