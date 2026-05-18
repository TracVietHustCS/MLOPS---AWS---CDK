set -e


read -p "Enter AWS Region [default: ap-northeast-2]: " USER_REGION
AWS_REGION=${USER_REGION:-ap-northeast-2}

AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}

read -p "Enter AWS ECR REPOSITORY_NAME [default: vllm-sagemaker]: " REPOSITORY_NAME
ECR_REPOSITORY_NAME=${REPOSITORY_NAME:-vllm-sagemaker}

VERSION_PREFIX=${VERSION_PREFIX:-v0.10.2-fp8-marlin}
UNIQUE_ID=$(python3 -c "import uuid; print(str(uuid.uuid4())[:8])")
IMAGE_TAG=${IMAGE_TAG:-${VERSION_PREFIX}-${UNIQUE_ID}}

DOCKERFILE_PATH="docker/vllm-lmi"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building Custom vLLM Container${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Configuration:"
echo "  AWS Region: ${AWS_REGION}"
echo "  AWS Account: ${AWS_ACCOUNT_ID}"
echo "  ECR Repository: ${ECR_REPOSITORY_NAME}"
echo "  Image Tag: ${IMAGE_TAG}"
echo "  Dockerfile Path: ${DOCKERFILE_PATH}"
echo ""

echo -e "${YELLOW}[1/5] Checking ECR repository...${NC}"
if ! aws ecr describe-repositories --repository-names ${ECR_REPOSITORY_NAME} --region ${AWS_REGION} > /dev/null 2>&1; then
    echo "Creating ECR repository: ${ECR_REPOSITORY_NAME}"
    aws ecr create-repository \
        --repository-name ${ECR_REPOSITORY_NAME} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    echo -e "${GREEN}✓ ECR repository created${NC}"
else
    echo -e "${GREEN}✓ ECR repository already exists${NC}"
fi
echo ""

echo -e "${YELLOW}[2/5] Logging into ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
echo -e "${GREEN}✓ Logged into ECR${NC}"
echo ""

ECR_IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}"
echo -e "${YELLOW}[3/5] Building Docker image...${NC}"
echo "Image URI: ${ECR_IMAGE_URI}"
echo ""

if [ ! -d "${DOCKERFILE_PATH}" ]; then
    echo -e "${RED}Error: ${DOCKERFILE_PATH} not found. Please run from project root.${NC}"
    exit 1
fi

DOCKER_BUILDKIT=1 docker build \
    --platform linux/amd64 \
    --tag ${ECR_IMAGE_URI} \
    --tag ${ECR_REPOSITORY_NAME}:latest \
    --progress=plain \
    ${DOCKERFILE_PATH}

echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

echo -e "${YELLOW}[4/5] Tagging image...${NC}"
docker tag ${ECR_REPOSITORY_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest
echo -e "${GREEN}✓ Image tagged${NC}"
echo ""

echo -e "${YELLOW}[5/5] Pushing image to ECR...${NC}"
docker push ${ECR_IMAGE_URI}
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest
echo -e "${GREEN}✓ Image pushed successfully${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Image Details:"
echo "  ECR URI: ${ECR_IMAGE_URI}"
echo "  Latest: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest"
echo ""
echo "Next Steps:"
echo "  1. Update terraform.tfvars with the new image URI:"
echo ""
echo "     custom_container_image = \"${ECR_IMAGE_URI}\""
echo ""
echo "  2. Apply Terraform changes:"
echo "     terraform apply"
echo ""
echo "Tip: Since the tag is unique (UUID), Terraform will automatically detect the change!"
echo ""

echo "${ECR_IMAGE_URI}" > .last_built_image.txt
echo "Image URI saved to: .last_built_image.txt"
echo ""
