resource "aws_api_gateway_api_key" "this" {
  name    = "${local.prefix}-key"
  enabled = true

  tags = local.tenant_tags
}

resource "aws_api_gateway_usage_plan" "this" {
  name = "${local.prefix}-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  throttle_settings {
    rate_limit  = var.tenant_config.throttle_rate_limit
    burst_limit = var.tenant_config.throttle_burst_limit
  }

  quota_settings {
    limit  = var.tenant_config.throttle_quota_per_month
    period = "MONTH"
  }

  tags = local.tenant_tags
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
