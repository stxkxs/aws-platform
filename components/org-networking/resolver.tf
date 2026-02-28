################################################################################
# Security Groups — Resolver Endpoints
################################################################################

resource "aws_security_group" "resolver" {
  count = var.enable_resolver ? 1 : 0

  name_prefix = "org-resolver-"
  description = "Security group for Route53 Resolver endpoints"
  vpc_id      = var.resolver_vpc_id

  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "org-resolver" })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Inbound Resolver Endpoint
################################################################################

resource "aws_route53_resolver_endpoint" "inbound" {
  count = var.enable_resolver ? 1 : 0

  name               = "org-resolver-inbound"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.resolver[0].id]

  dynamic "ip_address" {
    for_each = var.resolver_subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }

  tags = merge(local.tags, { Name = "org-resolver-inbound" })
}

################################################################################
# Outbound Resolver Endpoint
################################################################################

resource "aws_route53_resolver_endpoint" "outbound" {
  count = var.enable_resolver && length(var.resolver_rules) > 0 ? 1 : 0

  name               = "org-resolver-outbound"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.resolver[0].id]

  dynamic "ip_address" {
    for_each = var.resolver_subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }

  tags = merge(local.tags, { Name = "org-resolver-outbound" })
}

################################################################################
# Resolver Rules
################################################################################

resource "aws_route53_resolver_rule" "this" {
  for_each = var.enable_resolver ? var.resolver_rules : {}

  domain_name          = each.value.domain_name
  name                 = each.key
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.rule_type == "FORWARD" ? aws_route53_resolver_endpoint.outbound[0].id : null

  dynamic "target_ip" {
    for_each = each.value.rule_type == "FORWARD" ? each.value.target_ips : []
    content {
      ip = target_ip.value
    }
  }

  tags = merge(local.tags, { Name = "org-resolver-${each.key}" })
}

################################################################################
# RAM — Share Resolver Rules
################################################################################

resource "aws_ram_resource_share" "resolver" {
  count = var.enable_resolver && length(var.resolver_rules) > 0 ? 1 : 0

  name                      = "org-resolver-rules"
  allow_external_principals = false
  tags                      = merge(local.tags, { Name = "org-resolver-rules-share" })
}

resource "aws_ram_resource_association" "resolver_rules" {
  for_each = var.enable_resolver && length(var.resolver_rules) > 0 ? var.resolver_rules : {}

  resource_arn       = aws_route53_resolver_rule.this[each.key].arn
  resource_share_arn = aws_ram_resource_share.resolver[0].arn
}

resource "aws_ram_principal_association" "resolver" {
  for_each = var.enable_resolver && length(var.ram_principals) > 0 ? toset(var.ram_principals) : toset([])

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.resolver[0].arn
}
