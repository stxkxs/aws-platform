################################################################################
# Glue Catalog Database + Optional Schema Registry
################################################################################

resource "aws_glue_catalog_database" "this" {
  name        = replace("${var.environment}_pipeline_${var.tenant_id}", "-", "_")
  catalog_id  = var.account_id
  description = "Data catalog for pipeline tenant ${var.tenant_id}"
}

resource "aws_glue_registry" "this" {
  count         = var.tenant_config.schema_registry_enabled ? 1 : 0
  registry_name = local.prefix
  description   = "Schema registry for pipeline tenant ${var.tenant_id}"
  tags          = local.tenant_tags
}
