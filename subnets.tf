resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = join("-", [var.vpc_name, "pri-rtb", var.availability_zones_ref[count.index]]),
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "private" {
  # count = length(var.private_subnet_cidr_blocks)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name                              = join("-", [var.vpc_name, "private-sub", var.availability_zones_ref[count.index]]),
      Project                           = var.project,
      Environment                       = var.environment,
      "kubernetes.io/role/internal-elb" = "1",
      "kubernetes.io/cluster/${var.eks_name}" = "owned"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# *********************

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = join("-", [var.vpc_name, "pub-rtb"]),
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                     = join("-", [var.vpc_name, "public-sub", var.availability_zones_ref[count.index]]),
      Project                  = var.project,
      Environment              = var.environment,
      "kubernetes.io/role/elb" = "1",
      "kubernetes.io/cluster/${var.eks_name}" = "owned"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}