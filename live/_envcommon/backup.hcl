terraform {
  source = "${dirname(find_in_parent_folders())}//components/backup"
}

inputs = {
  team = "sre"
}
