include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/network.hcl"
  merge_strategy = "deep"
}

inputs = {
  nat_gateways         = 2
  enable_flow_logs     = true
  enable_vpc_endpoints = true
}
