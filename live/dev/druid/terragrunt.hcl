include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/druid.hcl"
  merge_strategy = "deep"
}

inputs = {
  tenants = {
    default = {
      rds_min_acu         = 0.5
      rds_max_acu         = 4
      rds_backup_days     = 3
      msk_enabled         = false
      deletion_protection = false
    }
  }
}
