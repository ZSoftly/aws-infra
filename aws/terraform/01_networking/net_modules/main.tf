# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-vpc-${var.region_short}"
  })
}

# Public Subnets for ALB
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => {
    cidr = cidr
    az   = element(var.availability_zones, idx)
    num  = idx + 1
  } }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false
  availability_zone       = each.value.az

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-pub-sn-${each.value.num}-${var.region_short}"
  })
}

# Private Subnets (Application)
resource "aws_subnet" "private_app" {
  for_each = { for idx, cidr in var.private_app_subnet_cidrs : idx => {
    cidr = cidr
    az   = element(var.availability_zones, idx)
    num  = idx + 1
  } }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-priv-app-sn-${each.value.num}-${var.region_short}"
  })
}

# Private Subnets (Database)
resource "aws_subnet" "private_db" {
  for_each = { for idx, cidr in var.private_db_subnet_cidrs : idx => {
    cidr = cidr
    az   = element(var.availability_zones, idx)
    num  = idx + 1
  } }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-priv-db-sn-${each.value.num}-${var.region_short}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-igw-${var.region_short}"
  })
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-pub-rtb-${var.region_short}"
  })
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_association" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for Private Subnets
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-nat-eip-${var.region_short}"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[1].id
  depends_on    = [aws_internet_gateway.igw]
  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-ngw-${var.region_short}"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-priv-rtb-${var.region_short}"
  })
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_association" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Security Groups - Create empty groups with only default egress rules
resource "aws_security_group" "alb" {
  name        = "${var.project_prefix}-${var.environment}-alb-sg-${var.region_short}"
  vpc_id      = aws_vpc.vpc.id
  description = "Security Group for ALB"

  # Default egress rule - all outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-alb-sg-${var.region_short}"
  })
}

resource "aws_security_group" "application" {
  name        = "${var.project_prefix}-${var.environment}-app-sg-${var.region_short}"
  vpc_id      = aws_vpc.vpc.id
  description = "Security Group for Application Instances"

  # Default egress rule - all outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-app-sg-${var.region_short}"
  })
}

resource "aws_security_group" "database" {
  name        = "${var.project_prefix}-${var.environment}-db-sg-${var.region_short}"
  vpc_id      = aws_vpc.vpc.id
  description = "Security Group for Database Instances"

  # Default egress rule - all outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-db-sg-${var.region_short}"
  })
}

resource "aws_security_group" "redis" {
  name        = "${var.project_prefix}-${var.environment}-redis-sg-${var.region_short}"
  vpc_id      = aws_vpc.vpc.id
  description = "Security Group for Redis Instances"

  # Default egress rule - all outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-redis-sg-${var.region_short}"
  })
}