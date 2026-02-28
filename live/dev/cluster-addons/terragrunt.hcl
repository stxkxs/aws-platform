include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/cluster-addons.hcl"
  merge_strategy = "deep"
}

inputs = {
  velero_enabled         = false
  opencost_enabled       = true
  keda_enabled           = false
  argo_events_enabled    = false
  argo_workflows_enabled = false
}
