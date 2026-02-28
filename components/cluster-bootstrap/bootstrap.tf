################################################################################
# Bootstrap: Cilium CNI
################################################################################

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.cilium_version
  namespace  = "kube-system"

  values = [yamlencode({
    eni = {
      enabled = true
    }
    ipam = {
      mode = "eni"
    }
    routingMode                = "native"
    egressMasqueradeInterfaces = "eth0"
    enableIPv4Masquerade       = false
    hubble = {
      enabled = true
      relay = {
        enabled = true
      }
      ui = {
        enabled = true
      }
    }
    encryption = {
      enabled = true
      type    = "wireguard"
    }
    bpf = {
      preallocateMaps = true
    }
    operator = {
      replicas = var.cilium_operator_replicas
    }
  })]

  lifecycle {
    ignore_changes = all
  }
}

################################################################################
# Disable aws-node DaemonSet (Cilium replaces VPC CNI)
################################################################################

resource "kubernetes_manifest" "disable_aws_node" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "DaemonSet"
    metadata = {
      name      = "aws-node"
      namespace = "kube-system"
    }
    spec = {
      selector = {
        matchLabels = {
          "k8s-app" = "aws-node"
        }
      }
      template = {
        metadata = {
          labels = {
            "k8s-app" = "aws-node"
          }
        }
        spec = {
          nodeSelector = {
            "io.cilium/aws-node-enabled" = "true"
          }
          containers = [{
            name  = "aws-node"
            image = "public.ecr.aws/eks/aws-node:latest"
          }]
        }
      }
    }
  }

  depends_on = [helm_release.cilium]
}

################################################################################
# Bootstrap: ArgoCD
################################################################################

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    server = {
      replicas = var.argocd_server_replicas
    }
    controller = {
      replicas = 1
    }
    repoServer = {
      replicas = var.argocd_repo_replicas
    }
    applicationSet = {
      replicas = var.argocd_appset_replicas
    }
  })]

  depends_on = [helm_release.cilium]
}

################################################################################
# ArgoCD Cluster Secret (drives ApplicationSet generators)
################################################################################

resource "kubernetes_secret_v1" "argocd_cluster" {
  metadata {
    name      = "in-cluster"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "environment"                    = var.environment
      "account_id"                     = local.account_id
      "region"                         = var.region
      "cluster_name"                   = var.cluster_name
    }
  }

  data = {
    name   = "in-cluster"
    server = "https://kubernetes.default.svc"
  }

  depends_on = [helm_release.argocd]
}

################################################################################
# ArgoCD Platform AppProject
################################################################################

resource "kubernetes_manifest" "platform_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform"
      namespace = "argocd"
    }
    spec = {
      description = "Platform infrastructure addons"
      sourceRepos = ["*"]
      destinations = [{
        server    = "https://kubernetes.default.svc"
        namespace = "*"
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  }

  depends_on = [helm_release.argocd]
}

################################################################################
# App-of-Apps Bootstrap Application
################################################################################

resource "kubernetes_manifest" "app_of_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "app-of-apps"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = "applicationsets"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }

  depends_on = [kubernetes_secret_v1.argocd_cluster]
}
