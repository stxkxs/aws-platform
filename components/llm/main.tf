data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  tags = merge(var.tags, {
    Component = "llm"
    Team      = var.team
  })
}

module "tenant" {
  for_each = var.tenants
  source   = "./modules/tenant"

  environment     = var.environment
  region          = var.region
  tenant_id       = each.key
  tenant_config   = each.value
  vpc_id          = var.vpc_id
  private_subnets = var.private_subnet_ids
  cluster_sg_id   = var.cluster_sg_id
  oidc_provider   = var.oidc_provider_arn
  oidc_issuer     = var.oidc_issuer
  tags            = local.tags
}
