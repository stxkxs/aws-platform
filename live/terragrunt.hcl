locals {
  account_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_id          = local.account_vars.locals.account_id
  region              = local.account_vars.locals.region
  environment         = local.account_vars.locals.environment
  cost_center         = local.account_vars.locals.cost_center
  business_unit       = local.account_vars.locals.business_unit
  data_classification = local.account_vars.locals.data_classification
  compliance          = local.account_vars.locals.compliance
  repository          = local.account_vars.locals.repository
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      Environment        = "${local.environment}"
      ManagedBy          = "opentofu"
      Project            = "aws-platform"
      CostCenter         = "${local.cost_center}"
      BusinessUnit       = "${local.business_unit}"
      DataClassification = "${local.data_classification}"
      Compliance         = "${local.compliance}"
      Repository         = "${local.repository}"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.account_id}-${local.region}-tfstate"
    key            = "${local.environment}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    use_lockfile   = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
