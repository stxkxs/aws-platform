################################################################################
# IRSA Roles for All Platform Addons
################################################################################

locals {
  irsa_role_prefix = "${var.environment}-eks"
}

# EBS CSI Driver
module "ebs_csi_irsa" {
  source = "../../modules/irsa"

  role_name         = "${local.irsa_role_prefix}-ebs-csi"
  oidc_provider_arn = local.oidc_provider_arn
  oidc_issuer       = local.oidc_issuer
  namespace         = "kube-system"
  service_account   = "ebs-csi-controller-sa"

  managed_policy_arns = [
    "arn:${local.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
  ]

  tags = local.tags
}
