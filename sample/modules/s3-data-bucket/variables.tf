variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed with objects"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "vpc_endpoint_id" {
  description = "VPC endpoint ID to restrict access"
  type        = string
  default     = null
}

variable "enable_vpc_endpoint_policy" {
  description = "Enable S3 bucket policy restricting access to VPC endpoint"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
