#
# public subnet routes
#
# NOTE: tags configured separately as not to conflict with tags from the install process
#
resource "aws_route_table" "rosa_public" {
  count = local.create_networking ? local.public_subnet_count : 0

  vpc_id = aws_vpc.rosa[0].id

  tags = merge(var.tags,
    {
      "Name" = "${var.cluster_name}-public-${aws_subnet.rosa_private[count.index].availability_zone}"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "rosa_public" {
  count = local.create_networking ? local.public_subnet_count : 0

  route_table_id         = aws_route_table.rosa_public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rosa[0].id
}

resource "aws_route_table_association" "rosa_public" {
  count = local.create_networking ? local.public_subnet_count : 0

  subnet_id      = aws_subnet.rosa_public[count.index].id
  route_table_id = aws_route_table.rosa_public[count.index].id
}

#
# private subnet routes
#
# NOTE: tags configured separately as not to conflict with tags from the install process
#
resource "aws_route_table" "rosa_private" {
  count = local.create_networking ? local.private_subnet_count : 0

  vpc_id = aws_vpc.rosa[0].id

  tags = merge(var.tags,
    {
      "Name" = "${var.cluster_name}-private-${aws_subnet.rosa_private[count.index].availability_zone}"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "rosa_private" {
  count = local.create_networking ? local.private_subnet_count : 0

  route_table_id         = aws_route_table.rosa_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.rosa_public[count.index].id
}

resource "aws_route_table_association" "rosa_private" {
  count = local.create_networking ? local.private_subnet_count : 0

  subnet_id      = aws_subnet.rosa_private[count.index].id
  route_table_id = aws_route_table.rosa_private[count.index].id
}
