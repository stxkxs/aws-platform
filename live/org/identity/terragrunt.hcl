include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/org-identity.hcl"
  merge_strategy = "deep"
}

inputs = {
  permission_sets = {
    Admin = {
      description      = "Full administrator access"
      session_duration  = "PT4H"
      managed_policies  = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy     = null
      boundary_policy   = null
    }
    PowerUser = {
      description      = "Power user access (no IAM management)"
      session_duration  = "PT8H"
      managed_policies  = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy     = null
      boundary_policy   = null
    }
    ReadOnly = {
      description      = "Read-only access to all resources"
      session_duration  = "PT12H"
      managed_policies  = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy     = null
      boundary_policy   = null
    }
    PlatformEngineer = {
      description      = "Platform engineering access"
      session_duration  = "PT8H"
      managed_policies  = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy     = null
      boundary_policy   = null
    }
    Developer = {
      description      = "Developer access for workloads"
      session_duration  = "PT8H"
      managed_policies  = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy     = null
      boundary_policy   = null
    }
  }

  groups = {
    platform-admins = { description = "Platform administrators with full access" }
    developers      = { description = "Development team members" }
    readonly        = { description = "Read-only stakeholders and auditors" }
    security-team   = { description = "Security team members" }
  }

  account_assignments = []
}
