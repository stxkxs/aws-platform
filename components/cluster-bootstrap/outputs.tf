output "cilium_version" {
  description = "Deployed Cilium version"
  value       = helm_release.cilium.version
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = helm_release.argocd.namespace
}
