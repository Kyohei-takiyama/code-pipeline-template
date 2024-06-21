resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  for_each                = var.subnets.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each       = var.subnets.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  for_each                = var.subnets.private_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
}

#######################################
## Nat Gateway
#######################################
resource "aws_eip" "this" {
  count      = length(var.subnets.private_subnets)
  vpc        = true
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this_1" {
  allocation_id = aws_eip.this[0].id
  subnet_id     = aws_subnet.public["public-1a"].id
}

resource "aws_nat_gateway" "this_2" {
  allocation_id = aws_eip.this[1].id
  subnet_id     = aws_subnet.public["public-1b"].id
}

resource "aws_route_table" "private" {
  count  = length(var.subnets.private_subnets)
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private[0].id
  nat_gateway_id         = aws_nat_gateway.this_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_2" {
  route_table_id         = aws_route_table.private[1].id
  nat_gateway_id         = aws_nat_gateway.this_2.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private["private-1a"].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private["private-1b"].id
  route_table_id = aws_route_table.private[1].id
}
