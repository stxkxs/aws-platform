terraform {
  source = "${dirname(find_in_parent_folders())}//components/org-compliance"
}

inputs = {
  team = "platform"
}
