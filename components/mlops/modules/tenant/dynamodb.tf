################################################################################
# DynamoDB Tables (Experiments, Model Registry)
################################################################################

resource "aws_dynamodb_table" "experiments" {
  name         = "${local.prefix}-experiments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "experimentId"
  range_key    = "runId"

  attribute {
    name = "experimentId"
    type = "S"
  }
  attribute {
    name = "runId"
    type = "S"
  }
  attribute {
    name = "status"
    type = "S"
  }
  attribute {
    name = "modelName"
    type = "S"
  }
  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "model-index"
    hash_key        = "modelName"
    range_key       = "createdAt"
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

resource "aws_dynamodb_table" "model_registry" {
  name         = "${local.prefix}-model-registry"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "modelName"
  range_key    = "version"

  attribute {
    name = "modelName"
    type = "S"
  }
  attribute {
    name = "version"
    type = "S"
  }
  attribute {
    name = "stage"
    type = "S"
  }
  attribute {
    name = "updatedAt"
    type = "S"
  }

  global_secondary_index {
    name            = "stage-index"
    hash_key        = "stage"
    range_key       = "updatedAt"
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
