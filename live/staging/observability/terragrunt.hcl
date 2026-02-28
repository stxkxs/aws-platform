include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/observability.hcl"
  merge_strategy = "deep"
}

inputs = {
  enable_cluster_alarms = true
  enable_dashboard      = true
  log_retention_days    = 30
}
