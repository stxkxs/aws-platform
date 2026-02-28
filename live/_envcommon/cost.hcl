terraform {
  source = "${dirname(find_in_parent_folders())}//components/cost"
}

inputs = {
  enable_tenant_anomaly_detection = false
  tenant_names                    = []
  team                            = "finops"
}
