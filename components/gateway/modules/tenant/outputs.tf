output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "rest_api_endpoint" {
  value = aws_api_gateway_stage.this.invoke_url
}

output "user_pool_id" {
  value = var.tenant_config.cognito_enabled ? aws_cognito_user_pool.this[0].id : null
}

output "waf_acl_arn" {
  value = var.tenant_config.waf_enabled ? aws_wafv2_web_acl.this[0].arn : null
}
