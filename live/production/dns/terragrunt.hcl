include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/dns.hcl"
  merge_strategy = "deep"
}

inputs = {
  domain_name        = "example.com"
  create_hosted_zone = true
  enable_dnssec      = true

  subdomain_prefixes = ["api", "app"]

  acm_certificates = {
    wildcard = {
      domain_name               = "*.example.com"
      subject_alternative_names = ["example.com"]
    }
    api = {
      domain_name               = "*.api.example.com"
      subject_alternative_names = ["api.example.com"]
    }
  }
}
