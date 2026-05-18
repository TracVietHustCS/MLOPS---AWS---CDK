variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "secrets" {
  description = <<-EOT
    Map of secrets to create. Each secret can have:
    - name: (required) Secret name suffix
    - description: (optional) Secret description
    - generate_random_password: (optional) Whether to generate a random password
    - password_length: (optional) Length of generated password (default: 32)
    - password_special: (optional) Include special characters (default: true)
    - password_override_special: (optional) Custom special characters
    - secret_string: (optional) Secret value if not generating random password
    - force_overwrite_replica_secret: (optional) Force overwrite replica secret
  EOT
  type = map(object({
    name                           = string
    description                    = optional(string)
    generate_random_password       = optional(bool, false)
    password_length                = optional(number, 32)
    password_special               = optional(bool, true)
    password_override_special      = optional(string)
    secret_string                  = optional(string)
    force_overwrite_replica_secret = optional(bool, false)
  }))
  default = {}
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting secrets (optional, uses AWS managed key if not provided)"
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before deleting a secret (0 to force immediate deletion)"
  type        = number
  default     = 30
}

variable "enable_rotation" {
  description = "Enable automatic rotation for secrets (requires rotation_lambda_arn)"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for secret rotation"
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Number of days between automatic scheduled rotations"
  type        = number
  default     = 30

  validation {
    condition     = var.rotation_days >= 1 && var.rotation_days <= 365
    error_message = "Rotation days must be between 1 and 365."
  }
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
