include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/backup.hcl"
  merge_strategy = "deep"
}

inputs = {
  enable_vault_lock = false

  backup_plans = {
    daily = {
      schedule       = "cron(0 3 * * ? *)"
      retention_days = 30
    }
  }
}
