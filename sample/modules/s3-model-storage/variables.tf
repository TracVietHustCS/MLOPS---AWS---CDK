variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional, uses AES256 if not provided)"
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy to clean up old versions"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which non-current versions are deleted"
  type        = number
  default     = 30
}

variable "sagemaker_execution_role_arns" {
  description = "List of SageMaker execution role ARNs that need access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
