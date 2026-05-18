variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for interface endpoints"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for VPC endpoints"
  type        = list(string)
}

variable "route_table_ids" {
  description = "Route table IDs for S3 gateway endpoint"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "create_s3_gateway" {
  description = "Create S3 gateway endpoint (free, but DNS resolves to public IP)"
  type        = bool
  default     = false
}

variable "create_s3_interface" {
  description = "Create S3 interface endpoint (costs money, but DNS resolves to private IP)"
  type        = bool
  default     = false
}

variable "sagemaker_endpoint" {
  description = "Create inference endpoint"
  type        = bool
  default     = false
}

variable "sagemaker_featurestore_endpoint" {
  description = "Create SageMaker Feature Store runtime endpoint"
  type        = bool
  default     = false
}

variable "ecr_endpoint" {
  description = "Create ecr endpoint"
  type        = bool
  default     = false
}

variable "ecr_dkr_endpoint" {
  description = "Create ecr docker endpoint"
  type        = bool
  default     = false
}

variable "cloudwatch_endpoint" {
  description = "Create cloudwatch endpoint"
  type        = bool
  default     = false
}

variable "secretsmanager_endpoint" {
  description = "Create secrets manager endpoint"
  type        = bool
  default     = false
}

variable "api_gateway_endpoint" {
  description = "Create API Gateway (execute-api) private endpoint"
  type        = bool
  default     = false
}

variable "lambda_endpoint" {
  description = "Create Lambda private endpoint"
  type        = bool
  default     = false
}


variable "ssm_endpoint" {
  description = "Create SSM endpoints (ssm, ssmmessages, ec2messages) for Session Manager"
  type        = bool
  default     = false
}

variable "cognito_endpoint" {
  description = "Create Cognito User Pool (cognito-idp) private endpoint"
  type        = bool
  default     = false
}
