variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "dashboard_name" {
  description = "CloudWatch dashboard name suffix"
  type        = string
  default     = "mlops"
}

variable "dashboard_body" {
  description = "Dashboard body JSON"
  type        = string
}

variable "metric_alarms" {
  description = "Map of CloudWatch metric alarms"
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    description         = optional(string)
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    dimensions          = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
