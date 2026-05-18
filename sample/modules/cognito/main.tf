# =============================================================================
# Cognito User Pool Module
# =============================================================================
# Tạo Cognito User Pool + App Clients để xác thực API Gateway
# Flow: Client → Cognito (lấy token) → API Gateway (verify token) → Lambda
# =============================================================================

# -----------------------------------------------------------------------------
# User Pool
# -----------------------------------------------------------------------------
resource "aws_cognito_user_pool" "this" {
  name = "${var.name_prefix}-${var.environment}-${var.user_pool_name}"

  deletion_protection = "ACTIVE"

  username_attributes      = var.use_alias_attributes ? null : ["email"]
  alias_attributes         = var.use_alias_attributes ? ["email"] : null
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length    = var.password_minimum_length
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  mfa_configuration = var.mfa_configuration

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  tags = merge(
    { Name = "${var.name_prefix}-${var.environment}-${var.user_pool_name}", Environment = var.environment },
    var.tags
  )

  lifecycle {
    ignore_changes = [name, tags, tags_all]
  }
}

# -----------------------------------------------------------------------------
# Resource Server (custom scopes for AccessToken)
# -----------------------------------------------------------------------------
resource "aws_cognito_resource_server" "this" {
  count        = var.create_resource_server ? 1 : 0
  identifier   = var.resource_server_identifier
  name         = "${var.name_prefix}-${var.environment}-api"
  user_pool_id = aws_cognito_user_pool.this.id

  dynamic "scope" {
    for_each = var.resource_server_scopes
    content {
      scope_name        = scope.value.name
      scope_description = scope.value.description
    }
  }
}


# -----------------------------------------------------------------------------
# App Client - SPA (no secret, for IdToken via initiate-auth)
# -----------------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "spa" {
  name         = "${var.name_prefix}-${var.environment}-api-spa-auth"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret     = false
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH"
  ]

  access_token_validity  = var.token_validity_minutes
  id_token_validity      = var.token_validity_minutes
  refresh_token_validity = var.refresh_token_validity_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  lifecycle {
    ignore_changes = [generate_secret]
  }
}

# -----------------------------------------------------------------------------
# App Client - Confidential (with secret, for AccessToken via client_credentials)
# -----------------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "confidential" {
  count        = var.create_resource_server ? 1 : 0
  name         = "${var.name_prefix}-${var.environment}-api-auth"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret     = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH"
  ]

  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = var.create_resource_server ? [for s in var.resource_server_scopes : "${var.resource_server_identifier}/${s.name}"] : []

  access_token_validity  = var.token_validity_minutes
  id_token_validity      = var.token_validity_minutes
  refresh_token_validity = var.refresh_token_validity_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  callback_urls = ["http://localhost"]

  lifecycle {
    ignore_changes = [generate_secret]
  }

  depends_on = [aws_cognito_resource_server.this]
}
