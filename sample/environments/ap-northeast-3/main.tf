terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
  }

  # Comment out for local testing, uncomment for production
  # backend "s3" {
  # }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "ACB-MHBDS"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = var.aws_region
      Owner       = "SWOVietnam_Hanoi"
    }
  }
}

# Provider for AWS Location Service (not available in all regions)
provider "aws" {
  alias   = "location"
  region  = var.location_service_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "ACB-MHBDS"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = var.location_service_region
      Owner       = "SWOVietnam_Hanoi"
    }
  }
}

data "aws_vpc" "main" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

data "aws_route_table" "sagemaker_route_tables" {
  for_each  = var.create_vpc ? toset([]) : toset(var.subnet_ids)
  subnet_id = each.value
}

data "aws_caller_identity" "current" {}

locals {
  permissions_boundary = var.enable_permissions_boundary ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary_policy_name}" : null
}
