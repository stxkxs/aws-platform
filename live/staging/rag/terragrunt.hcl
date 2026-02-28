include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/rag.hcl"
  merge_strategy = "deep"
}

inputs = {
  tenants = {
    default = {
      opensearch_standby_replicas = false
    }
  }
}
