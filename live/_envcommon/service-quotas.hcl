terraform {
  source = "${dirname(find_in_parent_folders())}//components/service-quotas"
}

inputs = {
  team = "platform"
}
