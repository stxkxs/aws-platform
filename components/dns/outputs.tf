output "hosted_zone_id" {
  description = "The ID of the primary hosted zone"
  value       = try(aws_route53_zone.primary[0].zone_id, "")
}

output "hosted_zone_name_servers" {
  description = "Name servers for the primary hosted zone (use for domain delegation)"
  value       = try(aws_route53_zone.primary[0].name_servers, [])
}

output "subdomain_zone_ids" {
  description = "Map of subdomain prefix to hosted zone ID"
  value = {
    for prefix, zone in aws_route53_zone.subdomains : prefix => zone.zone_id
  }
}

output "subdomain_name_servers" {
  description = "Map of subdomain prefix to name servers"
  value = {
    for prefix, zone in aws_route53_zone.subdomains : prefix => zone.name_servers
  }
}

output "acm_certificate_arns" {
  description = "Map of certificate key to ACM certificate ARN"
  value = {
    for k, cert in aws_acm_certificate.this : k => cert.arn
  }
}

output "domain_name" {
  description = "The primary domain name"
  value       = var.domain_name
}
