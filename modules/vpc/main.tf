# Three-tier VPC: public (NAT/ALB), private-app (ECS tasks), private-data (Aurora/Redis).
# Multi-AZ. Flow logs to CloudWatch (Volume 10). No public IPs on app/data subnets.
locals {
  az_count = length(var.availability_zones)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "unero-${var.environment}" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "unero-${var.environment}-igw" })
}

# --- Subnets: one /20 per tier per AZ, carved from the VPC CIDR ---
resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index)
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "unero-${var.environment}-public-${count.index}", Tier = "public" })
}

resource "aws_subnet" "app" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + local.az_count)
  tags              = merge(var.tags, { Name = "unero-${var.environment}-app-${count.index}", Tier = "app" })
}

resource "aws_subnet" "data" {
  count             = local.az_count
  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + (local.az_count * 2))
  tags              = merge(var.tags, { Name = "unero-${var.environment}-data-${count.index}", Tier = "data" })
}

# --- NAT: one per AZ in production, single in lower envs to save cost ---
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : local.az_count
  domain = "vpc"
  tags   = merge(var.tags, { Name = "unero-${var.environment}-nat-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.single_nat_gateway ? 1 : local.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.tags, { Name = "unero-${var.environment}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.this]
}

# --- Route tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "unero-${var.environment}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = local.az_count
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
  }
  tags = merge(var.tags, { Name = "unero-${var.environment}-private-rt-${count.index}" })
}

resource "aws_route_table_association" "app" {
  count          = local.az_count
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "data" {
  count          = local.az_count
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- VPC flow logs (Volume 10) ---
resource "aws_flow_log" "this" {
  log_destination          = var.flow_log_group_arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  iam_role_arn             = var.flow_log_role_arn
  max_aggregation_interval = 60
  tags                     = var.tags
}
