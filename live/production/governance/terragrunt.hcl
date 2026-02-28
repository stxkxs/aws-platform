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
      object_lock_enabled = true
    }
  }
}
