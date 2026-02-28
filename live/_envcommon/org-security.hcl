terraform {
  source = "${dirname(find_in_parent_folders())}//components/org-security"
}

inputs = {
  team = "platform"
}
