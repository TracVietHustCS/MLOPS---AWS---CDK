variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "resource_name" {
  description = "Resource name for the security group"
  type        = string
}

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = "Security group"
}

variable "ingress_rules" {
  description = "Map of ingress rules"
  type = map(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string))
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of egress rules"
  type = map(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string))
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
