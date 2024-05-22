resource "aws_vpc" "rosa" {
  count = local.create_networking ? 1 : 0

  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags,
    {
      "Name" = var.cluster_name
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
}
