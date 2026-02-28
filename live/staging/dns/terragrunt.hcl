include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/dns.hcl"
  merge_strategy = "deep"
}

inputs = {
  domain_name        = "staging.example.com"
  create_hosted_zone = true
  enable_dnssec      = false

  subdomain_prefixes = ["api", "app"]

  acm_certificates = {
    wildcard = {
      domain_name               = "*.staging.example.com"
      subject_alternative_names = ["staging.example.com"]
    }
    api = {
      domain_name               = "*.api.staging.example.com"
      subject_alternative_names = ["api.staging.example.com"]
    }
  }
}
