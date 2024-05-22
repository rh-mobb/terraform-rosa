locals {
  create_networking = (length(var.network.private_subnet_ids) == 0) && (length(var.network.public_subnet_ids) == 0)

  vpc_cidr = "${var.network.vpc_network}/${var.network.vpc_cidr_size}"

  private_subnet_count = local.create_networking ? (var.network.multi_az ? 3 : 1) : length(var.network.private_subnet_ids)
  public_subnet_count  = local.create_networking ? (var.network.multi_az ? 3 : 1) : length(var.network.public_subnet_ids)

  _all_cidrs = [
    for index in range(local.private_subnet_count + local.public_subnet_count) :
    cidrsubnet(local.vpc_cidr, (var.network.subnet_cidr_size - var.network.vpc_cidr_size), index)
  ]

  subnets_private = slice(local._all_cidrs, 0, local.private_subnet_count)
  subnets_public  = slice(local._all_cidrs, local.public_subnet_count, (length(local._all_cidrs)))
}
