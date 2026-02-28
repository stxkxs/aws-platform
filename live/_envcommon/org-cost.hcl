terraform {
  source = "${dirname(find_in_parent_folders())}//components/org-cost"
}

inputs = {
  team = "platform"
}
