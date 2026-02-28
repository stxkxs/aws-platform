terraform {
  source = "${dirname(find_in_parent_folders())}//components/org-identity"
}

inputs = {
  team = "platform"
}
