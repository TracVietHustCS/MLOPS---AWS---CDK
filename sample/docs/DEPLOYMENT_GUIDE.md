# ACB Deployment Guide

Complete step-by-step guide for deploying the ACB infrastructure.

## Prerequisites

### Required Tools
- Terraform >= 1.8.0
- AWS CLI v2
- Docker with BuildKit support
- Python 3.8+

### AWS Requirements

**VPC and Networking:**
- Existing VPC with DNS hostnames and DNS support enabled
- At least 2 private subnets in different AZs (for SageMaker)
- At least 2 public subnets in different AZs (for ALB)
- NAT Gateway for private subnet internet access

**Service Quotas:**
- SageMaker: ml.g5.24xlarge (30B FP8 models) and ml.g5.2xlarge (7-14B models)
- VPC: Available IP addresses in subnets

### AWS Credentials

#### Recommended: EC2 Instance with IAM Role

```bash
# Create IAM role for EC2 deployment
aws iam create-role --role-name acb-deployment-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach required policies
aws iam attach-role-policy \
  --role-name acb-deployment-role \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Verify
aws sts get-caller-identity
```

## Initial Setup

### 1. Enable VPC DNS Settings

```bash
export VPC_ID="vpc-xxxxxxxxx"
export AWS_REGION="ap-northeast-1"

aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames --region ${AWS_REGION}
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support --region ${AWS_REGION}
```

### 2. Create Terraform Backend Bucket

```bash
export STATE_BUCKET="acb-terraform-state-${AWS_REGION}"

aws s3api create-bucket \
  --bucket ${STATE_BUCKET} \
  --region ${AWS_REGION} \
  --create-bucket-configuration LocationConstraint=${AWS_REGION}

aws s3api put-bucket-versioning --bucket ${STATE_BUCKET} --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket ${STATE_BUCKET} \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### 3. Configure Backend

Edit `environments/<region>/backend.tfvars`:

```hcl
bucket  = "acb-terraform-state-ap-northeast-1"
key     = "ap-northeast-1/terraform.tfstate"
region  = "ap-northeast-1"
encrypt = true
```

## Step-by-Step Deployment

### Phase 1: Create S3 Bucket and VPC Endpoints

```bash
cd environments/ap-northeast-1

# Configure terraform.tfvars
# Set vpc_id, subnet_ids, and feature flags

terraform init -backend-config=backend.tfvars
terraform apply -target=module.s3_model_storage -target=module.vpc_endpoints
```

### Phase 2: Prepare and Upload Models

```bash
cd ../../common/sagemaker-builder

# Download and upload text model
python3 prepare_and_upload_model.py \
  --model-id "Qwen/Qwen2.5-7B-Instruct" \
  --model-name "qwen2.5-7b" \
  --bucket "acb-dev-models-ap-northeast-1-<random>" \
  --region "ap-northeast-1"

# Download and upload vision model (optional)
python3 prepare_and_upload_model.py \
  --model-id "Qwen/Qwen2.5-VL-7B-Instruct" \
  --model-name "qwen2.5-vl-7b" \
  --bucket "acb-dev-models-ap-northeast-1-<random>" \
  --region "ap-northeast-1"
```

### Phase 3: Deploy Full Infrastructure

Update `terraform.tfvars`:

```hcl
aws_region  = "ap-northeast-1"
environment = "dev"
name_prefix = "acb"

vpc_id     = "vpc-xxxxxxxxx"
subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]

deploy_text_model   = true
deploy_vision_model = false

text_model_name    = "qwen2.5-7b"
text_instance_type = "ml.g5.2xlarge"

tags = {
  Project     = "ACB"
  Environment = "dev"
  ManagedBy   = "Terraform"
}
```

```bash
cd environments/ap-northeast-1
terraform plan
terraform apply
```

Deployment time: ~15-20 minutes (SageMaker endpoints take 10-15 min).

### Phase 4: Verify Deployment

```bash
# Check SageMaker endpoint status
aws sagemaker describe-endpoint \
  --endpoint-name acb-dev-qwen2.5-7b \
  --region ap-northeast-1 \
  --query 'EndpointStatus'

# View outputs
terraform output
```

## Cost Optimization

### SageMaker Autoscaling

```hcl
enable_autoscaling_text    = true
text_min_instance_count    = 1
text_max_instance_count    = 3
target_concurrent_requests = 10
```

### Auto-Scheduler (start/stop endpoints off-hours)

```hcl
enable_endpoint_scheduler       = true
schedule_on_off_text_endpoint   = true
scheduler_stop_cron             = "cron(0 11 ? * MON-FRI *)"  # 6 PM VNT
scheduler_start_cron            = "cron(0 1 ? * MON-FRI *)"   # 8 AM VNT
```

Combined autoscaling + scheduler can reduce costs up to 80%.

### MLOps Modules (optional)

Enable MLOps infrastructure as needed:

```hcl
deploy_mlops_rds              = true   # RDS PostgreSQL for metadata
deploy_mlops_feature_store    = true   # SageMaker Feature Store
deploy_mlops_model_registry   = true   # Model Registry
deploy_mlops_pipeline         = true   # SageMaker Pipeline
deploy_mlops_model_monitoring = true   # Model Monitoring
```

## Multi-Region Deployment

```bash
# Copy environment template
cp -r environments/ap-northeast-1 environments/<new-region>

# Update terraform.tfvars and backend.tfvars with new region values
# Then follow the same deployment steps
```

## Troubleshooting

### SageMaker Endpoint Fails to Create
- Check service quota for the instance type
- Try smaller instance type: `ml.g5.2xlarge`

### First Inference Timeout
- First request takes 3-4 minutes for model warmup
- Increase client timeout to 300 seconds

### Terraform State Lock Error
```bash
terraform force-unlock <lock-id>
```

## Related Documentation

- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Architecture and modules
- [RUNBOOK.md](RUNBOOK.md) - Operations and maintenance
- [SUPER_QUICK_START.md](SUPER_QUICK_START.md) - Quick start
