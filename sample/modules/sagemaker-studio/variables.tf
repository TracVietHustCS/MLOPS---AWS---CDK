variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Studio Domain"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Studio Domain"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for Studio"
  type        = list(string)
  default     = []
}

variable "execution_role_arn" {
  description = "Default execution role ARN for Studio users"
  type        = string
}

variable "auth_mode" {
  description = "Authentication mode (IAM or SSO)"
  type        = string
  default     = "IAM"
}

variable "default_instance_type" {
  description = "Default notebook instance type"
  type        = string
  default     = "ml.m5.xlarge"
}

variable "jupyter_server_instance_type" {
  description = "Jupyter server instance type"
  type        = string
  default     = "system"
}

variable "jupyter_server_image_arn" {
  description = "Custom Jupyter server image ARN"
  type        = string
  default     = null
}

variable "kernel_gateway_image_arn" {
  description = "Custom kernel gateway image ARN"
  type        = string
  default     = null
}

variable "notebook_output_option" {
  description = "Notebook output sharing option (Allowed or Disabled)"
  type        = string
  default     = "Allowed"
}

variable "s3_output_path" {
  description = "S3 path for notebook outputs"
  type        = string
  default     = null
}

variable "retain_efs" {
  description = "Retain EFS home directory on domain deletion"
  type        = bool
  default     = false
}

variable "user_profiles" {
  description = "List of user profiles to create"
  type = list(object({
    name                   = string
    execution_role_arn     = optional(string)
    jupyter_instance_type  = optional(string)
    notebook_instance_type = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "app_network_access_type" {
  description = "Network access type for apps (PublicInternetOnly or VpcOnly)"
  type        = string
  default     = "VpcOnly"
}
