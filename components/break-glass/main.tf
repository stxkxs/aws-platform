data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  tags = merge(var.tags, {
    Component = "break-glass"
    Team      = var.team
  })
}

################################################################################
# Break-Glass IAM Role
################################################################################

resource "aws_iam_role" "break_glass" {
  name                 = "${var.environment}-break-glass"
  max_session_duration = var.max_session_duration
  permissions_boundary = var.enable_permissions_boundary ? aws_iam_policy.boundary[0].arn : null

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = [for id in var.trusted_account_ids : "arn:${local.partition}:iam::${id}:root"]
      }
      Action = "sts:AssumeRole"
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })

  tags = merge(local.tags, {
    BreakGlass = "true"
  })
}

resource "aws_iam_role_policy_attachment" "break_glass_admin" {
  role       = aws_iam_role.break_glass.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}

################################################################################
# Permissions Boundary
################################################################################

resource "aws_iam_policy" "boundary" {
  count = var.enable_permissions_boundary ? 1 : 0

  name        = "${var.environment}-break-glass-boundary"
  description = "Permissions boundary for break-glass role — prevents IAM/STS/Orgs modifications"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAll"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyIAMModifications"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "organizations:*",
        ]
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

################################################################################
# CloudWatch Alarm on Break-Glass Usage
################################################################################

resource "aws_cloudwatch_log_group" "break_glass" {
  name              = "/${var.environment}/break-glass"
  retention_in_days = 365

  tags = local.tags
}

resource "aws_sns_topic" "break_glass" {
  name = "${var.environment}-break-glass-alert"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "break_glass_email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.break_glass.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "break_glass_usage" {
  alarm_name          = "${var.environment}-break-glass-role-assumed"
  alarm_description   = "Alert when break-glass role is assumed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "BreakGlassAssumeRole"
  namespace           = "Custom/Security"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.break_glass.arn]
  ok_actions    = [aws_sns_topic.break_glass.arn]

  tags = local.tags
}

################################################################################
# EventBridge Rule for Break-Glass Detection
################################################################################

resource "aws_cloudwatch_event_rule" "break_glass" {
  name        = "${var.environment}-break-glass-detection"
  description = "Detect break-glass role assumption"

  event_pattern = jsonencode({
    source      = ["aws.sts"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["AssumeRole"]
      requestParameters = {
        roleArn = [aws_iam_role.break_glass.arn]
      }
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "break_glass_sns" {
  rule = aws_cloudwatch_event_rule.break_glass.name
  arn  = aws_sns_topic.break_glass.arn
}

resource "aws_sns_topic_policy" "break_glass_eventbridge" {
  arn = aws_sns_topic.break_glass.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridge"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.break_glass.arn
    }]
  })
}

################################################################################
# SSM Parameters
################################################################################

resource "aws_ssm_parameter" "break_glass_role_arn" {
  name  = "/${var.environment}/break-glass/role-arn"
  type  = "String"
  value = aws_iam_role.break_glass.arn

  tags = local.tags
}
