resource "aws_internet_gateway" "rosa" {
  count = local.create_networking ? 1 : 0

  vpc_id = aws_vpc.rosa[0].id

  tags = merge(var.tags, { "Name" = var.cluster_name })

  lifecycle {
    ignore_changes = [tags]
  }
}
