resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = format("%s-%s", var.vpc_name, "igw"),
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [aws_internet_gateway.default]

  # count = length(var.public_subnet_cidr_blocks)

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    {
      Name        = join("-", [var.vpc_name, "natGW", var.availability_zones_ref[0]]),
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}