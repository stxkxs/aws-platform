terraform {
  source = "${dirname(find_in_parent_folders())}//components/break-glass"
}

inputs = {
  team = "security"
}
