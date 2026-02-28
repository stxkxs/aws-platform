################################################################################
# Security Hub
################################################################################

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards = false
}

################################################################################
# Standards Subscriptions
################################################################################

resource "aws_securityhub_standards_subscription" "this" {
  for_each = var.enable_security_hub ? toset(var.securityhub_standards) : toset([])

  standards_arn = each.value

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# Security Hub Member Accounts
################################################################################

resource "aws_securityhub_member" "this" {
  for_each = var.enable_security_hub ? var.member_accounts : {}

  account_id = each.value.account_id
  email      = each.value.email
  invite     = true

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# Cross-Region Aggregation
################################################################################

resource "aws_securityhub_finding_aggregator" "this" {
  count = var.enable_security_hub && var.enable_cross_region_aggregation ? 1 : 0

  linking_mode = "ALL_REGIONS"

  depends_on = [aws_securityhub_account.this]
}

################################################################################
# EventBridge Rule — Critical/High Security Hub Findings
################################################################################

resource "aws_cloudwatch_event_rule" "securityhub_critical" {
  count = var.enable_security_hub ? 1 : 0

  name        = "org-securityhub-critical-findings"
  description = "Capture CRITICAL and HIGH Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
      }
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "securityhub_to_sns" {
  count = var.enable_security_hub ? 1 : 0

  rule      = aws_cloudwatch_event_rule.securityhub_critical[0].name
  target_id = "securityhub-to-sns"
  arn       = aws_sns_topic.security_alerts.arn
}
