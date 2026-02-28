include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/break-glass.hcl"
  merge_strategy = "deep"
}

inputs = {
  trusted_account_ids         = ["123456789012"]
  max_session_duration        = 3600
  enable_permissions_boundary = true
}
