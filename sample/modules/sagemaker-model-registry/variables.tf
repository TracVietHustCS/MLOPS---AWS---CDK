variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "model_package_group_name" {
  description = "Name of the model package group"
  type        = string
}

variable "model_package_group_description" {
  description = "Description of the model package group"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
