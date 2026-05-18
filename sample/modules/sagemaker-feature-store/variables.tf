variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "feature_group_name" {
  description = "Name of the feature group"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role for SageMaker Feature Store"
  type        = string
}

variable "record_identifier_name" {
  description = "Name of the feature that uniquely identifies each record"
  type        = string
}

variable "event_time_name" {
  description = "Name of the feature that stores the event time"
  type        = string
}

variable "feature_definitions" {
  description = "List of feature definitions (name and type pairs)"
  type = list(object({
    feature_name = string
    feature_type = string
  }))

  validation {
    condition = alltrue([
      for fd in var.feature_definitions : contains(["Integral", "Fractional", "String"], fd.feature_type)
    ])
    error_message = "Feature type must be one of: Integral, Fractional, String."
  }
}

variable "enable_online_store" {
  description = "Enable online store for real-time feature retrieval"
  type        = bool
  default     = true
}

variable "online_store_kms_key_id" {
  description = "KMS key ID for online store encryption"
  type        = string
  default     = null
}

variable "enable_offline_store" {
  description = "Enable offline store for batch feature retrieval"
  type        = bool
  default     = false
}

variable "offline_store_s3_uri" {
  description = "S3 URI for offline store data"
  type        = string
  default     = null
}

variable "offline_store_kms_key_id" {
  description = "KMS key ID for offline store encryption"
  type        = string
  default     = null
}

variable "offline_store_table_format" {
  description = "Table format for offline store (Glue or Iceberg)"
  type        = string
  default     = "Glue"

  validation {
    condition     = contains(["Glue", "Iceberg"], var.offline_store_table_format)
    error_message = "Table format must be either 'Glue' or 'Iceberg'."
  }
}

variable "disable_glue_table_creation" {
  description = "Disable automatic Glue table creation"
  type        = bool
  default     = false
}

variable "glue_catalog_config" {
  description = "Glue Data Catalog configuration for offline store"
  type = object({
    catalog    = string
    database   = string
    table_name = string
  })
  default = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
