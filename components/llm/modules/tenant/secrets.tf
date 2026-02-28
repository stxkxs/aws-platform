resource "aws_secretsmanager_secret" "hf_token" {
  count       = var.tenant_config.hf_token_enabled ? 1 : 0
  name        = "llm/${var.environment}/${var.tenant_id}/hf-token"
  description = "HuggingFace token for LLM tenant ${var.tenant_id}"
  tags        = local.tenant_tags
}
