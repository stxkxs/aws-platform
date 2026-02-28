include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/pipeline.hcl"
  merge_strategy = "deep"
}

inputs = {
  tenants = {
    default = {
      deletion_protection  = false
      msk_enabled          = false
      batch_max_vcpus      = 16
      batch_type           = "FARGATE_SPOT"
      sfn_logging_level    = "ALL"
      raw_lifecycle_ia_days = 30
      raw_lifecycle_expiry_days = 90
      staging_lifecycle_expiry_days = 30
      curated_version_expiry_days = 90
    }
  }
}
