# =============================================================================
# Import Commands - ap-southeast-1
# =============================================================================
# terraform import 'module.vpc[0].aws_vpc.main' vpc-039f27e7075c7f171
# terraform import 'module.vpc[0].aws_internet_gateway.main' igw-0a7c01a2ab4d7e12c
# terraform import 'module.vpc[0].aws_subnet.public_1' subnet-0ebdfdd3b99947e26
# terraform import 'module.vpc[0].aws_subnet.public_2' subnet-0e8fd2f42f1979bbd
# terraform import 'module.vpc[0].aws_subnet.private_1' subnet-0d374745153c083cb
# terraform import 'module.vpc[0].aws_subnet.private_2' subnet-06c8518ae89f72b1a
# terraform import 'module.vpc[0].aws_route_table.public' rtb-0fa0cc5a4cf5e4f92
# terraform import 'module.vpc[0].aws_route_table.private_1' rtb-0e95ebfd10150dfd4
# terraform import 'module.vpc[0].aws_route_table.private_2' rtb-0a4472a7b65a8ce1e
# terraform import 'module.vpc[0].aws_route_table_association.public_1' subnet-0ebdfdd3b99947e26/rtb-0fa0cc5a4cf5e4f92
# terraform import 'module.vpc[0].aws_route_table_association.public_2' subnet-0e8fd2f42f1979bbd/rtb-0fa0cc5a4cf5e4f92
# terraform import 'module.vpc[0].aws_route_table_association.private_1' subnet-0d374745153c083cb/rtb-0e95ebfd10150dfd4
# terraform import 'module.vpc[0].aws_route_table_association.private_2' subnet-06c8518ae89f72b1a/rtb-0a4472a7b65a8ce1e


# =============================================================================
# VPC Module
# =============================================================================
# Creates VPC with public + private subnets, IGW, NAT Gateway
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-vpc"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-igw"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# -----------------------------------------------------------------------------
# Public Subnets (for NAT Gateway, ALB only - no auto public IP)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false  # Disable auto public IP

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-public-1"
      Type = "Public"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false  # Disable auto public IP

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-public-2"
      Type = "Public"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# -----------------------------------------------------------------------------
# Private Subnets (for SageMaker, RDS, etc.)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-private-1"
      Type = "Private"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-private-2"
      Type = "Private"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway (for private subnet internet access)
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_1.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-rtb-public"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-rtb-private1"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.environment}-rtb-private2"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}
