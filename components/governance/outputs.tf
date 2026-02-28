output "tenants" {
  description = "Per-tenant governance resource map"
  value = {
    for tid, t in module.tenant : tid => {
      audit_bucket_name       = t.audit_bucket_name
      audit_bucket_arn        = t.audit_bucket_arn
      audit_kms_key_arn       = t.audit_kms_key_arn
      guardrail_bucket_name   = t.guardrail_bucket_name
      guardrail_bucket_arn    = t.guardrail_bucket_arn
      audit_table_name        = t.audit_table_name
      audit_table_arn         = t.audit_table_arn
      cost_table_name         = t.cost_table_name
      cost_table_arn          = t.cost_table_arn
      event_bus_name          = t.event_bus_name
      event_bus_arn           = t.event_bus_arn
      audit_writer_role_arn   = t.audit_writer_role_arn
      governance_api_role_arn = t.governance_api_role_arn
      namespace               = t.namespace
    }
  }
}
