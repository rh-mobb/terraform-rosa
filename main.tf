#
# network
#
module "network" {
  source = "github.com/scottd018-demos/rosa-vpc"

  network = {
    private_link       = var.private
    multi_az           = var.multi_az
    vpc_network        = split("/", var.vpc_cidr)[0]
    vpc_cidr_size      = tonumber(split("/", var.vpc_cidr)[1])
    subnet_cidr_size   = 20
    public_subnet_ids  = []
    private_subnet_ids = []
  }

  tags = local.tags
}

#
# cluster
#
resource "ocm_cluster_rosa_classic" "rosa_public" {
  name                       = var.cluster_name
  cloud_region               = var.region
  version                    = var.ocp_version
  aws_account_id             = data.aws_caller_identity.current.account_id
  disable_waiting_in_destroy = false

  # autoscaling
  autoscaling_enabled = var.autoscaling
  min_replicas        = var.autoscaling ? local.autoscaling_min : null
  max_replicas        = var.autoscaling ? local.autoscaling_max : null

  # network
  aws_private_link   = var.private
  aws_subnet_ids     = module.network.private_subnet_ids
  machine_cidr       = var.vpc_cidr
  availability_zones = module.network.private_subnet_azs

  tags = local.tags

  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }

  sts = local.sts_roles
}
