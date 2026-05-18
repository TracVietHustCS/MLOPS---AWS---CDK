variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "key_name" {
  description = "Name suffix for the KMS key"
  type        = string
  default     = "main"
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "KMS key for encryption"
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Whether the key is a multi-region key"
  type        = bool
  default     = false
}

variable "key_policy" {
  description = "Custom key policy JSON. If null, a default policy is used"
  type        = string
  default     = null
}

variable "key_administrators" {
  description = "List of IAM ARNs that can administer the key"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs that can use the key for encryption/decryption"
  type        = list(string)
  default     = []
}

variable "allowed_services" {
  description = "List of AWS service principals allowed to use the key"
  type        = list(string)
  default = [
    "s3.amazonaws.com",
    "sagemaker.amazonaws.com",
    "secretsmanager.amazonaws.com",
    "rds.amazonaws.com",
    "logs.amazonaws.com"
  ]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
