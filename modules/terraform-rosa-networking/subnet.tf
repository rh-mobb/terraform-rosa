resource "aws_subnet" "rosa_public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.rosa[0].id
  cidr_block              = local.subnets_public[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags,
    {
      "Name"                   = "${var.cluster_name}-public-${data.aws_availability_zones.available.names[count.index]}",
      "kubernetes.io/role/elb" = "1"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "rosa_private" {
  count = local.private_subnet_count

  vpc_id                  = aws_vpc.rosa[0].id
  cidr_block              = local.subnets_private[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags,
    {
      "Name"                            = "${var.cluster_name}-private-${data.aws_availability_zones.available.names[count.index]}",
      "kubernetes.io/role/internal-elb" = "1"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
}
