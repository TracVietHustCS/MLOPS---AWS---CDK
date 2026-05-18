variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "CodeBuild project name suffix"
  type        = string
}

variable "description" {
  description = "Project description"
  type        = string
  default     = "MLOps CodeBuild project"
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 60
}

variable "service_role_arn" {
  description = "IAM role ARN for CodeBuild. If null, a default role is created"
  type        = string
  default     = null
}

variable "artifacts_type" {
  description = "Build output artifact type (NO_ARTIFACTS, S3, CODEPIPELINE)"
  type        = string
  default     = "NO_ARTIFACTS"
}

variable "compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_MEDIUM"
}

variable "build_image" {
  description = "Docker image for the build environment"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "environment_type" {
  description = "Build environment type"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "privileged_mode" {
  description = "Enable privileged mode (required for Docker builds)"
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Environment variables for the build"
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "PLAINTEXT")
  }))
  default = []
}

variable "source_type" {
  description = "Source type (CODECOMMIT, GITHUB, S3, NO_SOURCE, CODEPIPELINE)"
  type        = string
  default     = "NO_SOURCE"
}

variable "buildspec" {
  description = "Buildspec content or file path"
  type        = string
  default     = ""
}

variable "source_location" {
  description = "Source location (repo URL or S3 path)"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID for CodeBuild (optional)"
  type        = string
  default     = null
}

variable "enable_vpc" {
  description = "Whether to enable VPC configuration for CodeBuild"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs for CodeBuild VPC config"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for CodeBuild VPC config"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting build artifacts"
  type        = string
  default     = null
}

variable "s3_log_bucket" {
  description = "S3 bucket for build logs"
  type        = string
  default     = null
}

variable "s3_access_arns" {
  description = "List of S3 ARNs that CodeBuild needs access to"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = null
}
