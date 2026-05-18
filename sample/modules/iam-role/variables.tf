variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "assume_role_policy" {
  description = "JSON policy document for assume role"
  type        = string
}

variable "inline_policies" {
  description = "Map of inline policy names to policy documents"
  type        = map(string)
  default     = {}
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}

variable "create_instance_profile" {
  description = "Create an instance profile for EC2 instances"
  type        = bool
  default     = false
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy to attach to the role"
  type        = string
  default     = null
}
