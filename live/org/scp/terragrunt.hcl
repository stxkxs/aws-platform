include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path           = "${dirname(find_in_parent_folders())}/_envcommon/org-scp.hcl"
  merge_strategy = "deep"
}

inputs = {
  policies = {
    DenyLeavingOrg = {
      description = "Prevent accounts from leaving the organization"
      target_ids  = []
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "DenyLeaveOrganization"
            Effect    = "Deny"
            Action    = "organizations:LeaveOrganization"
            Resource  = "*"
          },
        ]
      })
    }

    DenyDisablingSecurity = {
      description = "Prevent disabling security services"
      target_ids  = []
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyDisablingSecurityServices"
            Effect = "Deny"
            Action = [
              "cloudtrail:DeleteTrail",
              "cloudtrail:StopLogging",
              "cloudtrail:UpdateTrail",
              "guardduty:DeleteDetector",
              "guardduty:DisassociateFromMasterAccount",
              "guardduty:UpdateDetector",
              "config:DeleteConfigurationRecorder",
              "config:DeleteDeliveryChannel",
              "config:StopConfigurationRecorder",
              "securityhub:DisableSecurityHub",
              "securityhub:DeleteMembers",
              "securityhub:DisassociateFromMasterAccount",
              "access-analyzer:DeleteAnalyzer",
            ]
            Resource = "*"
          },
        ]
      })
    }

    DenyRootUserActions = {
      description = "Deny actions by root user"
      target_ids  = []
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "DenyRootUserActions"
            Effect    = "Deny"
            Action    = "*"
            Resource  = "*"
            Condition = {
              StringLike = {
                "aws:PrincipalArn" = "arn:aws:iam::*:root"
              }
            }
          },
        ]
      })
    }

    RegionRestriction = {
      description = "Restrict actions to allowed regions"
      target_ids  = []
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "DenyOutsideAllowedRegions"
            Effect    = "Deny"
            NotAction = [
              "a4b:*",
              "budgets:*",
              "ce:*",
              "chime:*",
              "cloudfront:*",
              "cur:*",
              "globalaccelerator:*",
              "health:*",
              "iam:*",
              "importexport:*",
              "organizations:*",
              "route53:*",
              "route53domains:*",
              "shield:*",
              "sts:*",
              "support:*",
              "trustedadvisor:*",
              "waf:*",
            ]
            Resource = "*"
            Condition = {
              StringNotEquals = {
                "aws:RequestedRegion" = [
                  "us-east-1",
                  "us-west-2",
                ]
              }
            }
          },
        ]
      })
    }

    NetworkGuardrails = {
      description = "Prevent insecure network configurations"
      target_ids  = []
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid      = "DenyDefaultVPC"
            Effect   = "Deny"
            Action   = "ec2:CreateDefaultVpc"
            Resource = "*"
          },
          {
            Sid      = "DenyDeleteFlowLogs"
            Effect   = "Deny"
            Action   = "ec2:DeleteFlowLogs"
            Resource = "*"
          },
          {
            Sid      = "DenyDisableEBSEncryption"
            Effect   = "Deny"
            Action   = "ec2:DisableEbsEncryptionByDefault"
            Resource = "*"
          },
        ]
      })
    }

    DataProtection = {
      description = "Enforce data protection controls"
      target_ids  = []
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid      = "DenyRemovingS3PublicAccessBlock"
            Effect   = "Deny"
            Action   = "s3:PutBucketPublicAccessBlock"
            Resource = "*"
          },
          {
            Sid      = "DenyUnencryptedS3Puts"
            Effect   = "Deny"
            Action   = "s3:PutObject"
            Resource = "*"
            Condition = {
              StringNotEquals = {
                "s3:x-amz-server-side-encryption" = ["AES256", "aws:kms"]
              }
              Null = {
                "s3:x-amz-server-side-encryption" = "false"
              }
            }
          },
          {
            Sid    = "DenyUnencryptedResources"
            Effect = "Deny"
            Action = [
              "rds:CreateDBInstance",
              "rds:CreateDBCluster",
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "rds:StorageEncrypted" = "false"
              }
            }
          },
          {
            Sid      = "DenyUnencryptedEBSVolumes"
            Effect   = "Deny"
            Action   = "ec2:CreateVolume"
            Resource = "*"
            Condition = {
              Bool = {
                "ec2:Encrypted" = "false"
              }
            }
          },
        ]
      })
    }
  }
}
