include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/cluster.hcl"
  merge_strategy = "deep"
}

inputs = {
  cluster_endpoint_public_access = false
  system_node_min_size           = 3
  system_node_max_size           = 9
  system_node_desired_size       = 3
  system_node_disk_size          = 100
}
