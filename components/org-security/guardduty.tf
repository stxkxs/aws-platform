################################################################################
# GuardDuty Detector
################################################################################

resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = var.guardduty_features.s3_protection
    }
    kubernetes {
      audit_logs {
        enable = var.guardduty_features.eks_audit_logs
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.guardduty_features.malware_protection
        }
      }
    }
  }

  tags = merge(local.tags, { Name = "org-guardduty-detector" })
}

################################################################################
# GuardDuty Detector Features
################################################################################

resource "aws_guardduty_detector_feature" "eks_runtime" {
  count = var.enable_guardduty && var.guardduty_features.eks_runtime_monitoring ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "EKS_RUNTIME_MONITORING"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "lambda" {
  count = var.enable_guardduty && var.guardduty_features.lambda_network_activity ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "rds" {
  count = var.enable_guardduty && var.guardduty_features.rds_login_events ? 1 : 0

  detector_id = aws_guardduty_detector.this[0].id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"
}

################################################################################
# GuardDuty Member Accounts
################################################################################

resource "aws_guardduty_member" "this" {
  for_each = var.enable_guardduty ? var.member_accounts : {}

  account_id  = each.value.account_id
  detector_id = aws_guardduty_detector.this[0].id
  email       = each.value.email
  invite      = true
}

################################################################################
# EventBridge Rule — High-Severity GuardDuty Findings
################################################################################

resource "aws_cloudwatch_event_rule" "guardduty_high_severity" {
  count = var.enable_guardduty ? 1 : 0

  name        = "org-guardduty-high-severity"
  description = "Capture high-severity GuardDuty findings (severity >= 7)"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  count = var.enable_guardduty ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_high_severity[0].name
  target_id = "guardduty-to-sns"
  arn       = aws_sns_topic.security_alerts.arn
}
