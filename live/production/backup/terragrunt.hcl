include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/backup.hcl"
  merge_strategy = "deep"
}

inputs = {
  enable_vault_lock = true

  backup_plans = {
    daily = {
      schedule       = "cron(0 3 * * ? *)"
      retention_days = 90
    }
    monthly = {
      schedule           = "cron(0 3 1 * ? *)"
      retention_days     = 365
      cold_storage_after = 30
    }
  }
}
