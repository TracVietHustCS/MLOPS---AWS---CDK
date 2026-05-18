variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "visibility_timeout" {
  description = "Visibility timeout in seconds"
  type        = number
  default     = 300
}

variable "message_retention" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600  # 4 days
}

variable "delay_seconds" {
  description = "Delay seconds for messages"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144  # 256 KB
}

variable "receive_wait_time" {
  description = "Long polling wait time in seconds"
  type        = number
  default     = 20
}

variable "enable_dlq" {
  description = "Enable dead letter queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Max receive count before sending to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention" {
  description = "DLQ message retention in seconds"
  type        = number
  default     = 1209600  # 14 days
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
