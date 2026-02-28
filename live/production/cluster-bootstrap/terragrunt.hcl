include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/cluster-bootstrap.hcl"
  merge_strategy = "deep"
}

inputs = {
  cilium_operator_replicas = 2
  argocd_server_replicas   = 3
  argocd_repo_replicas     = 3
  argocd_appset_replicas   = 2
}
