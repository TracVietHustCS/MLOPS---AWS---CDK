# ACB Operations Runbook

## Quick Reference

```bash
# Check SageMaker endpoint status
aws sagemaker describe-endpoint \
  --endpoint-name <endpoint-name> \
  --region <region> \
  --query 'EndpointStatus'

# View SageMaker logs
aws logs tail /aws/sagemaker/Endpoints/<endpoint-name> \
  --region <region> --follow

# View Lambda scheduler logs
aws logs tail /aws/lambda/acb-sagemaker-scheduler \
  --region <region> --follow

# Terraform state
cd environments/<region>
terraform state list
terraform output
```

## Common Operations

### Update SageMaker Endpoint Configuration

```bash
cd environments/ap-northeast-1
# Edit terraform.tfvars (instance type, count, etc.)
terraform apply -target=module.sagemaker_endpoint_text[0]
```

Wait 10-15 minutes for endpoint update.

### Scale SageMaker Endpoints

```hcl
# In terraform.tfvars
text_initial_instance_count = 2  # Manual scaling
# OR
enable_autoscaling_text    = true
text_min_instance_count    = 1
text_max_instance_count    = 3
target_concurrent_requests = 10
```

### Monitor Autoscaling

```bash
# Check current instance count
aws sagemaker describe-endpoint \
  --endpoint-name acb-dev-qwen2.5-7b \
  --region ap-northeast-1 \
  --query 'ProductionVariants[0].{Current:CurrentInstanceCount,Desired:DesiredInstanceCount}'

# View scaling activities
aws application-autoscaling describe-scaling-activities \
  --service-namespace sagemaker \
  --resource-id endpoint/acb-dev-qwen2.5-7b/variant/AllTraffic \
  --region ap-northeast-1 --max-results 10
```

### Manage Auto-Scheduler

```hcl
# Enable in terraform.tfvars
enable_endpoint_scheduler       = true
schedule_on_off_text_endpoint   = true
scheduler_stop_cron             = "cron(0 11 ? * MON-FRI *)"  # 6 PM VNT
scheduler_start_cron            = "cron(0 1 ? * MON-FRI *)"   # 8 AM VNT
```

### Manual Endpoint Stop/Start

```bash
# Stop (delete endpoint, keep config and model)
aws sagemaker delete-endpoint --endpoint-name acb-dev-qwen2.5-7b --region ap-northeast-1

# Start (recreate from existing config)
aws sagemaker create-endpoint \
  --endpoint-name acb-dev-qwen2.5-7b \
  --endpoint-config-name acb-dev-qwen2.5-7b-config \
  --region ap-northeast-1
```

### Upload New Model Version

```bash
cd common/sagemaker-builder
python3 prepare_and_upload_model.py \
  --model-id "Qwen/Qwen2.5-14B-Instruct" \
  --model-name "qwen2.5-14b" \
  --bucket "acb-dev-models-ap-northeast-1-<random>" \
  --region "ap-northeast-1"

# Update terraform.tfvars and apply
cd ../../environments/ap-northeast-1
terraform apply -target=module.sagemaker_endpoint_text[0]
```

## Troubleshooting

### High Latency
1. Scale up instance count or use larger instance type
2. Adjust model parameters (reduce max_model_len)
3. Check for cold starts

### Endpoint Errors
```bash
aws logs tail /aws/sagemaker/Endpoints/acb-dev-qwen2.5-7b \
  --region ap-northeast-1 --since 1h --filter-pattern "ERROR"
```

### Autoscaling Not Triggering
```bash
aws application-autoscaling describe-scalable-targets \
  --service-namespace sagemaker \
  --resource-ids endpoint/acb-dev-qwen2.5-7b/variant/AllTraffic \
  --region ap-northeast-1
```

### VPC Connectivity Issues
- Verify VPC DNS settings enabled
- Check security group rules
- Verify VPC endpoints are available

## Maintenance

### Weekly
- Check endpoint health and metrics
- Review autoscaling activity
- Monitor costs

### Monthly
- Clean up old ECR images
- Review old endpoint configs
- Update Terraform providers: `terraform init -upgrade`
- Review IAM permissions

## Emergency Procedures

### Rollback Deployment
```bash
cd environments/ap-northeast-1
# Revert terraform.tfvars changes
terraform apply -target=module.sagemaker_endpoint_text[0]
```

### Disaster Recovery
```bash
# Deploy to backup region
cd environments/ap-southeast-1
terraform apply
```

## Related Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Architecture and modules
