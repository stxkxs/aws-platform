variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name (e.g. example.com)"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create the hosted zone or import an existing one"
  type        = bool
  default     = true
}

variable "subdomain_prefixes" {
  description = "Additional subdomains to create zones for (e.g. [\"api\", \"app\"])"
  type        = list(string)
  default     = []
}

variable "enable_dnssec" {
  description = "Enable DNSSEC signing on the primary hosted zone"
  type        = bool
  default     = false
}

variable "acm_certificates" {
  description = "Map of ACM certificates to create with DNS validation"
  type = map(object({
    domain_name               = string
    subject_alternative_names = optional(list(string), [])
    wait_for_validation       = optional(bool, true)
  }))
  default = {}
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
