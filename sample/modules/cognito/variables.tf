variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "user_pool_name" {
  description = "Cognito User Pool name suffix"
  type        = string
  default     = "api-auth"
}

variable "mfa_configuration" {
  description = "MFA configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OFF"
}

variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 8
}

variable "token_validity_minutes" {
  description = "Access/ID token validity in minutes"
  type        = number
  default     = 60
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity in days"
  type        = number
  default     = 5
}

# Resource Server (for AccessToken with custom scopes)
variable "create_resource_server" {
  description = "Create resource server for custom OAuth scopes"
  type        = bool
  default     = false
}

variable "resource_server_identifier" {
  description = "Resource server identifier URI"
  type        = string
  default     = "https://api"
}

variable "resource_server_scopes" {
  description = "Custom scopes for resource server"
  type = list(object({
    name        = string
    description = string
  }))
  default = [
    { name = "read", description = "Read access" }
  ]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}


variable "cognito_domain_prefix" {
  description = "Cognito domain prefix (auto-generated if not specified)"
  type        = string
  default     = null
}


variable "use_alias_attributes" {
  description = "Use alias_attributes instead of username_attributes (for pools created via Console)"
  type        = bool
  default     = false
}
