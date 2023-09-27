data "aws_caller_identity" "current" {}

locals {
  # sts roles
  sts_roles = {
    role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-Installer-Role",
    support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-Support-Role",
    instance_iam_roles = {
      master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-ControlPlane-Role",
      worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-Worker-Role"
    },
    operator_role_prefix = var.cluster_name,
  }

  # autoscaling
  autoscaling_min = var.multi_az ? 3 : 2
  autoscaling_max = var.multi_az ? 6 : 4

  # required owner tag
  tags = {
    "owner" = data.aws_caller_identity.current.arn
  }
}

#
# cluster
#
locals {
  subnet_ids = var.private ? module.network.private_subnet_ids : concat(module.network.private_subnet_ids, module.network.public_subnet_ids)
}

resource "rhcs_cluster_rosa_classic" "rosa" {
  name = var.cluster_name

  # aws
  cloud_region   = var.region
  aws_account_id = data.aws_caller_identity.current.account_id
  tags           = local.tags

  # autoscaling
  autoscaling_enabled = var.autoscaling
  min_replicas        = var.autoscaling ? local.autoscaling_min : null
  max_replicas        = var.autoscaling ? local.autoscaling_max : null

  # network
  private            = var.private
  aws_private_link   = var.private
  aws_subnet_ids     = local.subnet_ids
  machine_cidr       = var.vpc_cidr
  availability_zones = module.network.private_subnet_azs
  multi_az           = var.multi_az

  # rosa / openshift
  properties = { rosa_creator_arn = data.aws_caller_identity.current.arn }
  version    = var.ocp_version
  sts        = local.sts_roles

  disable_waiting_in_destroy = false

  depends_on = [module.network, module.account_roles]
}

resource "rhcs_cluster_wait" "rosa" {
  cluster = rhcs_cluster_rosa_classic.rosa.id
  timeout = 60

  depends_on = [module.operator_roles]
}
