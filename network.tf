data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [data.aws_region.current.name]
  }

  filter {
    name   = "group-name"
    values = [data.aws_region.current.name]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_subnet" "selected" {
  count = length(var.private_subnet_ids)

  id = var.private_subnet_ids[count.index]
}

locals {
  create_networking = length(var.private_subnet_ids) < 1

  # retrieve the availability zones either from those which were input, or those which are availabie if 
  # we will be creating the netwokring on behalf of the user.
  availability_zones = local.create_networking ? (
    var.multi_az ?
    slice(
      [for zone in data.aws_availability_zones.available.names : zone],
      0,
      3
    ) :
    slice(
      [for zone in data.aws_availability_zones.available.names : zone],
      0,
      1
    )
  ) : [for subnet in data.aws_subnet.selected : subnet.availability_zone]

  # retrieve the subnet count.  if we are creating the networking, we derive the subnet count from the 
  # multi_az variable.  if we are not creating the networking, we are simply counting the subnets that 
  # the user has passed in.
  private_subnet_count = local.create_networking ? (var.multi_az ? 3 : 1) : length(var.private_subnet_ids)
  public_subnet_count  = local.create_networking ? (var.multi_az ? 3 : 1) : length(var.public_subnet_ids)

  # retrieve the subnet cidrs based on the requested VPC address range and the requested subnet CIDR size.
  subnet_cidrs = local.create_networking ? [
    for index in range(local.private_subnet_count + local.public_subnet_count) :
    cidrsubnet(var.vpc_cidr, (var.subnet_cidr_size - tonumber(split("/", var.vpc_cidr)[1])), index)
  ] : []

  # retrieve the private and public subnet cidrs.
  private_subnet_cidrs = local.create_networking ? slice(local.subnet_cidrs, 0, local.private_subnet_count) : []
  public_subnet_cidrs  = local.create_networking ? slice(local.subnet_cidrs, local.public_subnet_count, (length(local.subnet_cidrs))) : []
}

module "network" {
  count = local.create_networking ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs             = local.availability_zones
  private_subnets = var.multi_az ? local.private_subnet_cidrs : [local.private_subnet_cidrs[0]]
  public_subnets  = var.multi_az ? local.public_subnet_cidrs : [local.public_subnet_cidrs[0]]

  # nat gateway
  enable_nat_gateway = true
  single_nat_gateway = false

  # dhcp option set
  enable_dns_hostnames = true
  enable_dns_support   = true

  # tagging
  tags                = var.tags
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
}

# derive the values based on whether we created networking, so that they are simpler to consume in other parts of the automation
locals {
  # vpc
  vpc_id = local.create_networking ? module.network[0].vpc_id : data.aws_subnet.selected[0].vpc_id

  # subnet ids
  private_subnet_ids = local.create_networking ? module.network[0].private_subnets : var.private_subnet_ids
  public_subnet_ids  = local.create_networking ? module.network[0].public_subnets : var.public_subnet_ids

  # route table ids
  # NOTE: the subnet lookup does not provide insight to the route table ids, so return a null value if the user passed
  #       us the subnet ids (create_networking).
  private_route_table_ids = local.create_networking ? module.network[0].private_route_table_ids : null
  public_route_table_ids  = local.create_networking ? module.network[0].public_route_table_ids : null
}
