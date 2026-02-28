variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "policies" {
  description = "Map of Service Control Policies to create and attach"
  type = map(object({
    description = string
    policy      = string
    target_ids  = list(string)
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
