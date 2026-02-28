################################################################################
# Step Functions State Machine (Conditional)
################################################################################

resource "aws_sfn_state_machine" "this" {
  count = var.tenant_config.step_functions_enabled ? 1 : 0

  name     = local.prefix
  role_arn = aws_iam_role.sfn[0].arn

  definition = jsonencode({
    Comment = "Pipeline orchestration for ${var.tenant_id}"
    StartAt = "Placeholder"
    States = {
      Placeholder = {
        Type = "Pass"
        End  = true
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn[0].arn}:*"
    include_execution_data = true
    level                  = var.tenant_config.sfn_logging_level
  }

  tracing_configuration {
    enabled = true
  }

  tags = local.tenant_tags
}

resource "aws_iam_role" "sfn" {
  count = var.tenant_config.step_functions_enabled ? 1 : 0
  name  = "${local.prefix}-sfn"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tenant_tags
}

resource "aws_iam_role_policy" "sfn" {
  count = var.tenant_config.step_functions_enabled ? 1 : 0
  name  = "${local.prefix}-sfn"
  role  = aws_iam_role.sfn[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "sfn" {
  count             = var.tenant_config.step_functions_enabled ? 1 : 0
  name              = "/aws/vendedlogs/states/${local.prefix}"
  retention_in_days = 30
  tags              = local.tenant_tags
}
