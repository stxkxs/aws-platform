terraform {
  source = "${dirname(find_in_parent_folders())}//components/dns"
}

inputs = {
  team = "platform"
}
