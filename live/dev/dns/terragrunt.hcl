include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/dns.hcl"
  merge_strategy = "deep"
}

inputs = {
  domain_name        = "dev.example.com"
  create_hosted_zone = true
  enable_dnssec      = false

  subdomain_prefixes = []

  acm_certificates = {
    wildcard = {
      domain_name               = "*.dev.example.com"
      subject_alternative_names = ["dev.example.com"]
    }
  }
}
