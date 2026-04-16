# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.common_tags, { Name = var.vpc_name })
}

# ─── SUBNETS ─────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(var.common_tags, { Name = "public-sn-${count.index + 1}" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = merge(var.common_tags, { Name = "private-sn-${count.index + 1}" })
}

# ─── INTERNET GATEWAY ────────────────────────────────────────────────────────

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.vpc_name}-igw" })
}

# ─── NAT GATEWAY ─────────────────────────────────────────────────────────────
# One NAT Gateway per AZ for high availability in production.
# For non-prod cost savings, set nat_gateway_count = 1 in tfvars.

resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.vpc_name}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.common_tags, { Name = "${var.vpc_name}-nat-${count.index + 1}" })
  depends_on    = [aws_internet_gateway.this]
}

# ─── ROUTE TABLES ────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One private route table per AZ, each pointing to its own NAT Gateway.
# If nat_gateway_count = 1, all private subnets share the single NAT.

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.vpc_name}-private-rt-${count.index + 1}" })
}

resource "aws_route" "private_nat" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[min(count.index, var.nat_gateway_count - 1)].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ─── VPC FLOW LOGS ───────────────────────────────────────────────────────────
# Captures all IP traffic in/out of the VPC for security auditing.

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/${var.vpc_name}/flow-logs"
  retention_in_days = var.log_retention_days
  tags              = var.common_tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  tags            = merge(var.common_tags, { Name = "${var.vpc_name}-flow-log" })
}
