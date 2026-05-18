variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateway"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Public subnet ID where NAT Gateway will be placed"
  type        = string
}

variable "private_route_table_ids" {
  description = "List of private route table IDs to add NAT route"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
