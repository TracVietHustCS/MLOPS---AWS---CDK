# Super Quick Start

## To create resources
```bash
export ENVIRONMENT="dev"
export REGION="ap-northeast-1"

# Create S3 bucket and VPC endpoints first
cd environments/${REGION}
terraform init -backend-config=backend.tfvars
terraform apply -target=module.s3_model_storage -target=module.vpc_endpoints

# Download models and upload to S3:
cd ../../common/sagemaker-builder
python3 prepare_and_upload_model.py \
  --model-id <hugging_face_model,eg: Qwen/Qwen2.5-VL-7B-Instruct> \
  --model-name <shortname, must match terraform vars: vision_model_name or text_model_name> \
  --bucket <take from first apply> \
  --region $REGION

# Deploy everything:
cd ../../environments/${REGION}
terraform apply
```

## To Destroy resources (clean-up)

/!\ Remember to clean-up S3 that stores models and ECR that stores images before running terraform destroy.

/!\ When destroying, the sagemaker_sg may take too long or fail because Terraform deletes the endpoint but doesn't wait for the instance to fully shut down, so the ENI won't be deleted. Fix:
- Go to EC2 -> Network Interface -> find the ENI with SageMaker in the description -> wait until status changes to Available -> Delete it
- If terraform already failed: Delete the ENI manually and run `terraform destroy` again
