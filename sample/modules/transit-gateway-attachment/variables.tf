# =============================================================================
# Transit Gateway Attachment Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Transit Gateway Configuration
# -----------------------------------------------------------------------------
variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach to"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to attach"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the attachment (one per AZ)"
  type        = list(string)
}

variable "dns_support" {
  description = "Enable DNS support"
  type        = bool
  default     = true
}

variable "ipv6_support" {
  description = "Enable IPv6 support"
  type        = bool
  default     = false
}

variable "appliance_mode_support" {
  description = "Enable appliance mode (for stateful network appliances)"
  type        = bool
  default     = false
}

variable "default_route_table_association" {
  description = "Associate with default TGW route table"
  type        = bool
  default     = true
}

variable "default_route_table_propagation" {
  description = "Propagate routes to default TGW route table"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Route Configuration
# -----------------------------------------------------------------------------
variable "create_routes" {
  description = "Create routes to Transit Gateway in specified route tables"
  type        = bool
  default     = true
}

variable "route_table_ids" {
  description = "List of route table IDs to add TGW routes"
  type        = list(string)
  default     = []
}

variable "destination_cidr_block" {
  description = "Destination CIDR for TGW route (e.g., on-premises network or other VPCs)"
  type        = string
  default     = "10.0.0.0/8"
}
