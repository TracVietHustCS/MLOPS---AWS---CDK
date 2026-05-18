
variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal or internet-facing"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the ALB"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach to the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where target groups will be created"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 bucket prefix for ALB access logs"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    name                             = string
    port                             = number
    protocol                         = string
    target_type                      = string
    health_check_enabled             = bool
    health_check_healthy_threshold   = optional(number, 2)
    health_check_unhealthy_threshold = optional(number, 2)
    health_check_timeout             = optional(number, 5)
    health_check_interval            = optional(number, 30)
    health_check_path                = optional(string, "/health")
    health_check_protocol            = optional(string)
    health_check_matcher             = optional(string, "200")
    deregistration_delay             = optional(number, 300)
    stickiness_enabled               = optional(bool, false)
    stickiness_type                  = optional(string, "lb_cookie")
    stickiness_cookie_duration       = optional(number, 86400)
    tags                             = optional(map(string), {})
  }))
  default = {}
}

variable "default_action" {
  description = "Default action for the listener when no rules match"
  type = object({
    type             = string
    target_group_key = optional(string)
    content_type     = optional(string, "text/plain")
    message_body     = optional(string, "OK")
    status_code      = optional(string, "200")
  })
  default = {
    type         = "fixed-response"
    content_type = "text/plain"
    message_body = "OK"
    status_code  = "200"
  }
}

variable "listener_rules" {
  description = "Map of listener rule configurations"
  type = map(object({
    priority         = number
    target_group_key = string
    path_patterns    = optional(list(string))
    host_headers     = optional(list(string))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
