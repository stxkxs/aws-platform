terraform {
  source = "${dirname(find_in_parent_folders())}//components/org-networking"
}

inputs = {
  team = "platform"
}
