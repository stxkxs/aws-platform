resource "aws_dynamodb_table" "inference" {
  name         = "${local.prefix}-inference"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "requestId"
  range_key    = "timestamp"

  attribute {
    name = "requestId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  dynamic "ttl" {
    for_each = var.tenant_config.dynamodb_ttl_enabled ? [1] : []
    content {
      attribute_name = "ttl"
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = var.tenant_config.dynamodb_pitr
  }

  deletion_protection_enabled = var.tenant_config.deletion_protection

  tags = local.tenant_tags
}
