output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = try(aws_ec2_transit_gateway.this[0].id, null)
}

output "transit_gateway_arn" {
  description = "Transit Gateway ARN"
  value       = try(aws_ec2_transit_gateway.this[0].arn, null)
}

output "ram_share_arn" {
  description = "RAM resource share ARN for Transit Gateway"
  value       = try(aws_ram_resource_share.tgw[0].arn, null)
}

output "ipam_id" {
  description = "VPC IPAM ID"
  value       = try(aws_vpc_ipam.this[0].id, null)
}

output "ipam_top_level_pool_id" {
  description = "IPAM top-level pool ID"
  value       = try(aws_vpc_ipam_pool.top_level[0].id, null)
}

output "ipam_env_pool_ids" {
  description = "Map of environment sub-pool name to pool ID"
  value       = { for k, v in aws_vpc_ipam_pool.env : k => v.id }
}

output "resolver_inbound_endpoint_id" {
  description = "Route53 Resolver inbound endpoint ID"
  value       = try(aws_route53_resolver_endpoint.inbound[0].id, null)
}

output "resolver_outbound_endpoint_id" {
  description = "Route53 Resolver outbound endpoint ID"
  value       = try(aws_route53_resolver_endpoint.outbound[0].id, null)
}

output "resolver_rule_ids" {
  description = "Map of resolver rule name to rule ID"
  value       = { for k, v in aws_route53_resolver_rule.this : k => v.id }
}
