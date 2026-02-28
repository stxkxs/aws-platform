resource "aws_cognito_user_pool" "this" {
  count = var.tenant_config.cognito_enabled ? 1 : 0

  name                     = "${local.prefix}-users"
  deletion_protection      = var.tenant_config.deletion_protection ? "ACTIVE" : "INACTIVE"
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = var.tenant_config.cognito_password_min
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = local.tenant_tags
}

resource "aws_cognito_user_pool_client" "this" {
  count = var.tenant_config.cognito_enabled ? 1 : 0

  name         = "${local.prefix}-app"
  user_pool_id = aws_cognito_user_pool.this[0].id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = var.tenant_config.cognito_access_token_hrs
  refresh_token_validity = var.tenant_config.cognito_refresh_token_days

  token_validity_units {
    access_token  = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "this" {
  count = var.tenant_config.cognito_enabled ? 1 : 0

  domain       = "${var.environment}-${var.tenant_id}-gateway"
  user_pool_id = aws_cognito_user_pool.this[0].id
}
