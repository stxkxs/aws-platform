include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/governance.hcl"
  merge_strategy = "deep"
}

inputs = {
  tenants = {
    default = {
      cost_ttl_days = 365
    }
  }
}
