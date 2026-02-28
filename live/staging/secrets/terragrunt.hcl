include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/secrets.hcl"
  merge_strategy = "deep"
}

inputs = {
  kms_deletion_window = 14
  enable_key_rotation = true

  secrets = {}
}
