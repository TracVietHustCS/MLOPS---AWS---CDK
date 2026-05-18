# ACB Project Structure

## Directory Structure

```
ACB/
├── common/
│   ├── sagemaker-builder/       # Model preparation tools
│   │   ├── docker/              # Custom container Dockerfiles
│   │   ├── prepare_and_upload_model.py
│   │   ├── build_and_push_vllm.sh
│   │   └── deploy_streaming.sh
│   └── tests/                   # Test scripts
│       ├── langchain_test/
│       ├── sdk.py
│       └── test_chat_streaming.py
│
├── environments/                # Region-specific deployments
│   ├── ap-northeast-1/          # Tokyo
│   ├── ap-northeast-2/          # Seoul
│   ├── ap-northeast-3/          # Osaka
│   └── ap-southeast-1/          # Singapore
│
├── modules/                     # Reusable Terraform modules
│   ├── alb/                     # Application Load Balancer
│   ├── api-gateway/             # API Gateway (Inference API Layer)
│   ├── rds-postgres/            # RDS PostgreSQL (MLOps metadata)
│   ├── cloudtrail/              # CloudTrail audit logging
│   ├── cloudwatch-dashboard/    # CloudWatch dashboards & alarms
│   ├── codebuild/               # CodeBuild projects (SageMaker container builds)
│   ├── ecr-repository/          # ECR repositories
│   ├── glue/                    # AWS Glue (ETL jobs, crawlers)
│   ├── iam-role/                # IAM roles
│   ├── kms/                     # KMS encryption keys
│   ├── lambda/                  # Lambda functions
│   ├── s3-model-storage/        # S3 model storage buckets
│   ├── sagemaker-endpoint/      # SageMaker endpoints
│   ├── sagemaker-feature-store/ # SageMaker Feature Store
│   ├── sagemaker-model-monitoring/ # SageMaker Model Monitoring
│   ├── sagemaker-model-registry/   # SageMaker Model Registry
│   ├── sagemaker-pipeline/      # SageMaker Pipeline
│   ├── secrets-manager/         # Secrets Manager
│   ├── security-group/          # Security groups
│   ├── vpc/                     # VPC networking
│   ├── vpc-endpoints/           # VPC endpoints
│   ├── vpc-flow-logs/           # VPC Flow Logs
│   ├── waf/                     # AWS WAF (Web Application Firewall)
│   ├── backup/                  # AWS Backup (automated backups)
│   ├── location-service/        # AWS Location Service (geocoding, maps, tracking)
│   ├── transit-gateway-attachment/ # Transit Gateway VPC attachment
│   └── aws-config/              # AWS Config (compliance monitoring)
│
├── lambda_functions/
│   └── sagemaker-scheduler/     # Endpoint start/stop scheduler
│
└── docs/                        # Documentation
```

## Architecture Overview

```
VPC (Private Subnets)
 │
 ├── SageMaker Endpoints (Text + Vision models)
 │    ├── S3 Model Storage
 │    ├── ECR (custom containers)
 │    └── IAM Roles
 │
 ├── MLOps Infrastructure
 │    ├── RDS PostgreSQL (metadata store)
 │    ├── Secrets Manager (credentials)
 │    ├── SageMaker Feature Store
 │    ├── SageMaker Model Registry
 │    ├── SageMaker Pipeline
 │    └── SageMaker Model Monitoring
 │
 ├── CI/CD
 │    └── CodeBuild (container build + model deploy)
 │
 ├── Security & Compliance
 │    ├── KMS (encryption for S3, RDS, ECR, Secrets Manager)
 │    ├── CloudTrail (audit logging)
 │    └── VPC Flow Logs (network monitoring)
 │
 ├── Lambda (Endpoint Scheduler)
 │
 ├── ALB (Load Balancing)
 │
 └── VPC Endpoints (S3, ECR, SageMaker, CloudWatch, Secrets Manager)
```

## Terraform Modules

### Core Infrastructure
- **alb** - Application Load Balancer with target groups and listener rules
- **iam-role** - IAM roles with inline policies and trust relationships
- **security-group** - Security groups with ingress/egress rules
- **vpc** - VPC with public/private subnets, IGW, NAT Gateway
- **vpc-endpoints** - Interface/Gateway endpoints for AWS services

### Storage
- **ecr-repository** - ECR repos with lifecycle policies and scan-on-push
- **s3-model-storage** - S3 buckets with versioning, encryption, lifecycle rules
- **secrets-manager** - Secrets with optional random password generation and rotation

### Compute
- **sagemaker-endpoint** - SageMaker endpoints with autoscaling, custom containers, VPC deployment
- **lambda** - Lambda functions with EventBridge rules for scheduling

### MLOps
- **rds-postgres** - RDS PostgreSQL for MLflow/metadata storage
- **sagemaker-feature-store** - Feature Groups with online/offline stores
- **sagemaker-model-registry** - Model Package Groups for model versioning
- **sagemaker-pipeline** - SageMaker Pipelines for ML workflows
- **sagemaker-model-monitoring** - Model monitoring with scheduled jobs
- **sagemaker-training** - SageMaker Training workflow with Step Functions orchestration

### CI/CD
- **codebuild** - CodeBuild projects for building containers and deploying models

### Security & Compliance
- **kms** - KMS keys with key rotation, service-level access policies
- **cloudtrail** - CloudTrail with CloudWatch log destinations
- **cloudwatch-dashboard** - CloudWatch dashboards and metric alarms
- **vpc-flow-logs** - VPC Flow Logs to CloudWatch or S3
- **waf** - AWS WAF for API Gateway protection with managed rules
- **backup** - AWS Backup for RDS and other resources
- **aws-config** - AWS Config for compliance monitoring and resource tracking

### Networking
- **vpc** - VPC with public/private subnets, IGW, NAT Gateway
- **vpc-endpoints** - Interface/Gateway endpoints for AWS services
- **transit-gateway-attachment** - Transit Gateway VPC attachment for cross-VPC connectivity

### Data Engineering
- **glue** - AWS Glue ETL jobs, crawlers, and connections for data ingestion
- **api-gateway** - API Gateway for inference API layer with Lambda integration
- **location-service** - AWS Location Service for geocoding, maps, tracking, geofencing, routing

## Environment Configuration

Each environment contains:
- `main.tf` - Provider and backend config
- `variables.tf` - Variable declarations
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values
- `backend.tfvars` - S3 backend config
- `iam.tf` - IAM roles
- `networking.tf` - VPC endpoints and networking
- `s3.tf` - S3 storage
- `security_groups.tf` - Security groups
- `sagemaker.tf` - SageMaker endpoints
- `lambda.tf` - Lambda scheduler
- `mlops.tf` - MLOps modules (RDS, Feature Store, Registry, Pipeline, Monitoring)
- `security.tf` - Security & Compliance (KMS, CloudTrail, VPC Flow Logs)
- `cicd.tf` - SageMaker CodeBuild

### Resource Naming Convention

Format: `{name_prefix}-{environment}-{resource_type}-{region}`

## Related Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Step-by-step deployment
- [RUNBOOK.md](RUNBOOK.md) - Operations and maintenance
- [SUPER_QUICK_START.md](SUPER_QUICK_START.md) - Quick start guide
