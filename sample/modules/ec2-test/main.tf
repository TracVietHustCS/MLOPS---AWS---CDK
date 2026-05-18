# =============================================================================
# EC2 Test Instance Module
# =============================================================================
# Creates a test EC2 instance with cloud-init to verify VPC endpoints
# Uses nslookup to check private IP resolution for AWS services
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Get Latest Amazon Linux 2023 AMI
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# -----------------------------------------------------------------------------
# IAM Role for EC2 (SSM access)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "test_instance" {
  name                 = "${var.name_prefix}-${var.environment}-test-instance"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.environment}-test-instance-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.test_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "test_instance" {
  name = "${var.name_prefix}-${var.environment}-test-instance"
  role = aws_iam_role.test_instance.name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Security Group for Test Instance
# -----------------------------------------------------------------------------
resource "aws_security_group" "test_instance" {
  name        = "${var.name_prefix}-${var.environment}-test-instance"
  description = "Security group for test EC2 instance"
  vpc_id      = var.vpc_id

  # Allow HTTPS outbound for VPC endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS to VPC endpoints"
  }

  # Allow DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS TCP"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.environment}-test-instance-sg"
  })
}

# -----------------------------------------------------------------------------
# Cloud-Init Script
# -----------------------------------------------------------------------------
locals {
  cloud_init_script = <<-EOF
#!/bin/bash
set -e

# Log file
LOG_FILE="/var/log/vpc-endpoint-test.log"
RESULT_FILE="/home/ec2-user/vpc-endpoint-results.txt"

echo "=== VPC Endpoint Test Started at $(date) ===" | tee $LOG_FILE

# Install required tools
dnf install -y bind-utils curl jq | tee -a $LOG_FILE

# Function to test endpoint
test_endpoint() {
    local service=$1
    local endpoint=$2
    echo "" | tee -a $LOG_FILE
    echo "Testing $service endpoint: $endpoint" | tee -a $LOG_FILE
    echo "-------------------------------------------" | tee -a $LOG_FILE
    
    # nslookup
    echo "nslookup result:" | tee -a $LOG_FILE
    nslookup $endpoint 2>&1 | tee -a $LOG_FILE
    
    # Get IP
    IP=$(dig +short $endpoint | head -1)
    if [[ $IP =~ ^10\. ]] || [[ $IP =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ $IP =~ ^192\.168\. ]]; then
        echo "✅ $service: Private IP detected ($IP)" | tee -a $LOG_FILE $RESULT_FILE
    else
        echo "❌ $service: Public IP or not resolved ($IP)" | tee -a $LOG_FILE $RESULT_FILE
    fi
}

# Region
REGION="${data.aws_region.current.id}"

echo "" | tee -a $LOG_FILE
echo "Region: $REGION" | tee -a $LOG_FILE
echo "VPC CIDR: ${var.vpc_cidr}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Clear result file
echo "=== VPC Endpoint Test Results ===" > $RESULT_FILE
echo "Timestamp: $(date)" >> $RESULT_FILE
echo "Region: $REGION" >> $RESULT_FILE
echo "" >> $RESULT_FILE

# Test VPC Endpoints
test_endpoint "S3" "s3.$REGION.amazonaws.com"
test_endpoint "SageMaker Runtime" "runtime.sagemaker.$REGION.amazonaws.com"
test_endpoint "SageMaker API" "api.sagemaker.$REGION.amazonaws.com"
test_endpoint "ECR API" "api.ecr.$REGION.amazonaws.com"
test_endpoint "ECR DKR" "dkr.ecr.$REGION.amazonaws.com"
test_endpoint "CloudWatch Logs" "logs.$REGION.amazonaws.com"
test_endpoint "Secrets Manager" "secretsmanager.$REGION.amazonaws.com"
test_endpoint "SSM" "ssm.$REGION.amazonaws.com"
test_endpoint "SSM Messages" "ssmmessages.$REGION.amazonaws.com"
test_endpoint "EC2 Messages" "ec2messages.$REGION.amazonaws.com"
test_endpoint "API Gateway" "execute-api.$REGION.amazonaws.com"
test_endpoint "Lambda" "lambda.$REGION.amazonaws.com"
test_endpoint "STS" "sts.$REGION.amazonaws.com"
test_endpoint "KMS" "kms.$REGION.amazonaws.com"

echo "" | tee -a $LOG_FILE
echo "=== Test Completed at $(date) ===" | tee -a $LOG_FILE

# Set permissions
chmod 644 $RESULT_FILE
chown ec2-user:ec2-user $RESULT_FILE

echo "" | tee -a $LOG_FILE
echo "Results saved to: $RESULT_FILE" | tee -a $LOG_FILE
echo "View with: cat $RESULT_FILE" | tee -a $LOG_FILE
EOF
}

# -----------------------------------------------------------------------------
# EC2 Test Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "test" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.test_instance.id]
  iam_instance_profile   = aws_iam_instance_profile.test_instance.name

  user_data_base64 = base64encode(local.cloud_init_script)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30  # Minimum size for AL2023 AMI
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.environment}-test-instance"
  })
}
