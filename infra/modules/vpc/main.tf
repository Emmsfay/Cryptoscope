# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true   # required for EKS node registration
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
    # EKS uses these tags to discover the VPC
    "kubernetes.io/cluster/${var.name_prefix}" = "shared"
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
# Allows resources in public subnets to reach the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.name_prefix}-igw" }
}

# ── Public Subnets ────────────────────────────────────────────────────────────
# One per AZ — hosts the ALB (load balancer) for inbound traffic
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    # Required tag for AWS Load Balancer Controller to discover public subnets
    "kubernetes.io/role/elb"                              = "1"
    "kubernetes.io/cluster/${var.name_prefix}"            = "shared"
  }
}

# ── Private Subnets ───────────────────────────────────────────────────────────
# One per AZ — hosts EKS worker nodes (not directly accessible from internet)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    # Required tag for AWS Load Balancer Controller to discover private subnets
    "kubernetes.io/role/internal-elb"                     = "1"
    "kubernetes.io/cluster/${var.name_prefix}"            = "shared"
  }
}

# ── NAT Gateways ──────────────────────────────────────────────────────────────
# Allow private subnet resources (EKS nodes) to reach the internet
# (e.g. to pull Docker images from ECR) — without exposing them publicly
# One NAT GW per AZ for high availability

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = { Name = "${var.name_prefix}-nat-eip-${count.index}" }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${var.name_prefix}-nat-${var.availability_zones[count.index]}" }

  depends_on = [aws_internet_gateway.main]
}

# ── Route Tables ──────────────────────────────────────────────────────────────

# Public route table — default route via Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route tables — one per AZ, each routed to its own NAT GW
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = { Name = "${var.name_prefix}-rt-private-${var.availability_zones[count.index]}" }
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
