################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = true

  authentication_mode = "API"

  encryption_config = {
    provider_key_arn = module.kms.key_arn
    resources        = ["secrets"]
  }

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # EKS managed add-ons (AWS-managed lifecycle)
  addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  # System node group — runs critical platform addons
  eks_managed_node_groups = {
    system = {
      name           = "${var.environment}-system"
      instance_types = var.system_node_instance_types
      ami_type       = "BOTTLEROCKET_x86_64"
      min_size       = var.system_node_min_size
      max_size       = var.system_node_max_size
      desired_size   = var.system_node_desired_size
      disk_size      = var.system_node_disk_size
      capacity_type  = "ON_DEMAND"

      labels = {
        "node-role" = "system"
      }

      taints = {
        critical = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  access_entries = var.access_entries

  # Allow Karpenter node role to join the cluster
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  tags = local.tags
}
