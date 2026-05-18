variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Database
variable "database_name" {
  description = "Glue catalog database name"
  type        = string
  default     = "mlops-data"
}

variable "database_description" {
  description = "Database description"
  type        = string
  default     = "MLOps data catalog for ETL jobs"
}

# Crawler
variable "create_crawler" {
  description = "Whether to create a Glue crawler"
  type        = bool
  default     = false
}

variable "crawler_name" {
  description = "Glue crawler name"
  type        = string
  default     = "data-crawler"
}

variable "crawler_schedule" {
  description = "Cron schedule for crawler (e.g., cron(0 12 * * ? *))"
  type        = string
  default     = null
}

variable "crawler_s3_targets" {
  description = "List of S3 targets for crawler"
  type = list(object({
    path       = string
    exclusions = optional(list(string), [])
  }))
  default = []
}

variable "crawler_delete_behavior" {
  description = "Behavior when crawler detects deleted objects"
  type        = string
  default     = "LOG"
}

variable "crawler_update_behavior" {
  description = "Behavior when crawler detects schema changes"
  type        = string
  default     = "UPDATE_IN_DATABASE"
}

# ETL Job
variable "create_etl_job" {
  description = "Whether to create a Glue ETL job"
  type        = bool
  default     = false
}

variable "job_name" {
  description = "Glue ETL job name"
  type        = string
  default     = "etl-job"
}

variable "job_script_location" {
  description = "S3 path to the ETL script"
  type        = string
  default     = null
}

variable "job_python_version" {
  description = "Python version for the job"
  type        = string
  default     = "3"
}

variable "glue_version" {
  description = "Glue version"
  type        = string
  default     = "4.0"
}

variable "job_worker_type" {
  description = "Worker type (Standard, G.1X, G.2X)"
  type        = string
  default     = "G.1X"
}

variable "job_number_of_workers" {
  description = "Number of workers"
  type        = number
  default     = 2
}

variable "job_timeout" {
  description = "Job timeout in minutes"
  type        = number
  default     = 60
}

variable "job_max_retries" {
  description = "Maximum number of retries"
  type        = number
  default     = 0
}

variable "job_max_concurrent_runs" {
  description = "Maximum concurrent runs"
  type        = number
  default     = 1
}

variable "job_default_arguments" {
  description = "Additional default arguments for the job"
  type        = map(string)
  default     = {}
}

variable "enable_delta_lake" {
  description = "Enable Delta Lake support for Glue jobs"
  type        = bool
  default     = false
}

variable "delta_lake_catalog_name" {
  description = "Name of the Delta Lake catalog (for Glue Data Catalog integration)"
  type        = string
  default     = "spark_catalog"
}

variable "job_logs_bucket" {
  description = "S3 bucket for job logs"
  type        = string
  default     = null
}

# Connection
variable "create_connection" {
  description = "Whether to create a Glue connection"
  type        = bool
  default     = false
}

variable "connection_name" {
  description = "Glue connection name"
  type        = string
  default     = "jdbc-connection"
}

variable "connection_type" {
  description = "Connection type (JDBC, KAFKA, MONGODB, NETWORK)"
  type        = string
  default     = "JDBC"
}

variable "connection_properties" {
  description = "Connection properties (JDBC_CONNECTION_URL, USERNAME, PASSWORD)"
  type        = map(string)
  default     = {}
}

variable "connection_availability_zone" {
  description = "Availability zone for the connection"
  type        = string
  default     = null
}

variable "connection_security_group_ids" {
  description = "Security group IDs for the connection"
  type        = list(string)
  default     = []
}

variable "connection_subnet_id" {
  description = "Subnet ID for the connection"
  type        = string
  default     = null
}

# IAM
variable "glue_role_arn" {
  description = "IAM role ARN for Glue. If null, a default role is created"
  type        = string
  default     = null
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = null
}

variable "s3_access_arns" {
  description = "List of S3 ARNs that Glue needs access to"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
