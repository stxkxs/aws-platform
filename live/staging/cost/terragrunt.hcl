include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/cost.hcl"
  merge_strategy = "deep"
}

inputs = {
  monthly_budget_limit     = 2000
  budget_alert_thresholds  = [50, 80, 100, 120]
  enable_anomaly_detection = true
  anomaly_threshold        = 100
  enable_cur_report        = false
}
