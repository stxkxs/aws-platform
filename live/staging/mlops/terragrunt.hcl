include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/mlops.hcl"
  merge_strategy = "deep"
}

inputs = {
  tenants = {
    default = {
      run_ttl_days                = 365
      deprecated_version_ttl_days = 365
    }
  }
}
