################################################################################
# VPC IPAM
################################################################################

locals {
  ipam_operating_regions = length(var.ipam_operating_regions) > 0 ? var.ipam_operating_regions : [var.region]
}

resource "aws_vpc_ipam" "this" {
  count = var.enable_ipam ? 1 : 0

  dynamic "operating_regions" {
    for_each = toset(local.ipam_operating_regions)
    content {
      region_name = operating_regions.value
    }
  }

  tags = merge(local.tags, { Name = "org-ipam" })
}

################################################################################
# Top-Level Pool
################################################################################

resource "aws_vpc_ipam_pool" "top_level" {
  count = var.enable_ipam ? 1 : 0

  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.this[0].private_default_scope_id
  description    = "Organization top-level pool"
  tags           = merge(local.tags, { Name = "org-ipam-top-level" })
}

resource "aws_vpc_ipam_pool_cidr" "top_level" {
  count = var.enable_ipam ? 1 : 0

  ipam_pool_id = aws_vpc_ipam_pool.top_level[0].id
  cidr         = var.ipam_top_level_cidr
}

################################################################################
# Environment Sub-Pools
################################################################################

resource "aws_vpc_ipam_pool" "env" {
  for_each = var.enable_ipam ? var.ipam_pools : {}

  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam.this[0].private_default_scope_id
  source_ipam_pool_id = aws_vpc_ipam_pool.top_level[0].id
  locale              = coalesce(each.value.locale, var.region)
  description         = each.value.description
  tags                = merge(local.tags, each.value.tags, { Name = "org-ipam-${each.key}" })
}

resource "aws_vpc_ipam_pool_cidr" "env" {
  for_each = var.enable_ipam ? var.ipam_pools : {}

  ipam_pool_id = aws_vpc_ipam_pool.env[each.key].id
  cidr         = each.value.cidr

  depends_on = [aws_vpc_ipam_pool_cidr.top_level]
}

################################################################################
# RAM — Share IPAM Pools
################################################################################

resource "aws_ram_resource_share" "ipam" {
  count = var.enable_ipam && length(var.ram_principals) > 0 ? 1 : 0

  name                      = "org-ipam-pools"
  allow_external_principals = false
  tags                      = merge(local.tags, { Name = "org-ipam-pools-share" })
}

resource "aws_ram_resource_association" "ipam_pools" {
  for_each = var.enable_ipam && length(var.ram_principals) > 0 ? var.ipam_pools : {}

  resource_arn       = aws_vpc_ipam_pool.env[each.key].arn
  resource_share_arn = aws_ram_resource_share.ipam[0].arn
}

resource "aws_ram_principal_association" "ipam" {
  for_each = var.enable_ipam && length(var.ram_principals) > 0 ? toset(var.ram_principals) : toset([])

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.ipam[0].arn
}
