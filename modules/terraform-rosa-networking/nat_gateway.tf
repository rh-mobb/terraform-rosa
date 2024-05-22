resource "aws_eip" "rosa_nat_gateway" {
  count = local.public_subnet_count

  tags = merge(var.tags,
    {
      "Name" = "${var.cluster_name}-natgw-${aws_subnet.rosa_public[count.index].availability_zone}"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [aws_internet_gateway.rosa]
}

resource "aws_nat_gateway" "rosa_public" {
  count = local.public_subnet_count

  subnet_id         = aws_subnet.rosa_public[count.index].id
  allocation_id     = aws_eip.rosa_nat_gateway[count.index].id
  connectivity_type = "public"

  tags = merge(var.tags,
    {
      "Name" = "${var.cluster_name}-natgw-${aws_subnet.rosa_public[count.index].availability_zone}"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [aws_internet_gateway.rosa]
}
