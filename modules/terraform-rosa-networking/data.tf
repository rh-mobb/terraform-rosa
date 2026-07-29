data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [data.aws_region.current.region]
  }

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_subnet" "private_selected" {
  count = local.create_networking ? 0 : length(var.network.private_subnet_ids)

  id = var.network.private_subnet_ids[count.index]
}

data "aws_subnet" "public_selected" {
  count = local.create_networking ? 0 : length(var.network.public_subnet_ids)

  id = var.network.public_subnet_ids[count.index]
}

data "aws_vpc" "selected" {
  count = local.create_networking ? 0 : 1

  id = data.aws_subnet.private_selected[0].vpc_id
}

check "selected_subnets_share_vpc" {
  assert {
    condition = local.create_networking ? true : alltrue(concat(
      [for subnet in data.aws_subnet.private_selected : subnet.vpc_id == data.aws_vpc.selected[0].id],
      [for subnet in data.aws_subnet.public_selected : subnet.vpc_id == data.aws_vpc.selected[0].id],
    ))
    error_message = "All pre-existing private and public subnets must belong to the same VPC."
  }
}
