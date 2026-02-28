terraform {
  source = "${dirname(find_in_parent_folders())}//components/network"
}

inputs = {
  cluster_name = "eks"
  team         = "platform"
}
