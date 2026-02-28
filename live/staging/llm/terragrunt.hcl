include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/llm.hcl"
  merge_strategy = "deep"
}

inputs = {
  tenants = {
    default = {
      efs_throughput_mode = "bursting"
    }
  }
}
