resource "aws_dynamodb_table" "audit" {
  name         = "${local.prefix}-audit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantDate"
  range_key    = "timestampRequestId"

  attribute {
    name = "tenantDate"
    type = "S"
  }
  attribute {
    name = "timestampRequestId"
    type = "S"
  }
  attribute {
    name = "modelId"
    type = "S"
  }
  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "S"
  }

  global_secondary_index {
    name            = "modelId-index"
    hash_key        = "modelId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.tenant_config.point_in_time_recovery
  }

  deletion_protection_enabled = var.tenant_config.deletion_protection

  tags = local.tenant_tags
}

resource "aws_dynamodb_table" "cost" {
  name         = "${local.prefix}-cost"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantModelId"
  range_key    = "dateHour"

  attribute {
    name = "tenantModelId"
    type = "S"
  }
  attribute {
    name = "dateHour"
    type = "S"
  }
  attribute {
    name = "date"
    type = "S"
  }

  global_secondary_index {
    name            = "date-index"
    hash_key        = "date"
    range_key       = "tenantModelId"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.tenant_config.point_in_time_recovery
  }

  deletion_protection_enabled = var.tenant_config.deletion_protection

  tags = local.tenant_tags
}
