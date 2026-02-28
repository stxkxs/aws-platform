include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/observability.hcl"
  merge_strategy = "deep"
}

inputs = {
  enable_cluster_alarms = false
  enable_dashboard      = true
  alert_email_endpoints = []
  log_retention_days    = 7
}
