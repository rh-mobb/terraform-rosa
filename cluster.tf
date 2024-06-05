data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # autoscaling
  autoscaling_min  = var.multi_az ? 3 : 2
  autoscaling_max  = var.multi_az ? 6 : 4
  default_replicas = var.multi_az ? 3 : 2
}

#
# cluster
#
locals {
  subnet_ids = var.private ? module.network.private_subnet_ids : concat(module.network.private_subnet_ids, module.network.public_subnet_ids)
}

# classic
resource "rhcs_cluster_rosa_classic" "rosa" {
  count = var.hosted_control_plane ? 0 : 1

  name = var.cluster_name

  # aws
  cloud_region   = var.region
  aws_account_id = data.aws_caller_identity.current.account_id
  tags           = var.tags

  # autoscaling
  autoscaling_enabled = var.autoscaling
  min_replicas        = var.autoscaling ? local.autoscaling_min : null
  max_replicas        = var.autoscaling ? local.autoscaling_max : null
  replicas            = var.autoscaling ? null : coalesce(var.replicas, local.default_replicas)

  # network
  private            = var.private
  aws_private_link   = var.private
  aws_subnet_ids     = local.subnet_ids
  machine_cidr       = var.vpc_cidr
  availability_zones = module.network.private_subnet_azs
  multi_az           = var.multi_az
  pod_cidr           = var.pod_cidr
  service_cidr       = var.service_cidr

  # rosa / openshift
  properties = { rosa_creator_arn = data.aws_caller_identity.current.arn }
  version    = var.ocp_version
  sts        = local.sts_roles

  disable_waiting_in_destroy = false
  wait_for_create_complete   = true

  depends_on = [module.network, module.account_roles_classic, module.operator_roles_classic]
}

# hosted control plane
resource "rhcs_cluster_rosa_hcp" "rosa" {
  count = var.hosted_control_plane ? 1 : 0

  name = var.cluster_name

  # aws
  cloud_region           = var.region
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_billing_account_id = data.aws_caller_identity.current.account_id
  tags                   = var.tags

  # network
  private            = var.private
  aws_subnet_ids     = local.subnet_ids
  machine_cidr       = var.vpc_cidr
  availability_zones = module.network.private_subnet_azs
  pod_cidr           = var.pod_cidr
  service_cidr       = var.service_cidr

  # rosa / openshift
  properties = { rosa_creator_arn = data.aws_caller_identity.current.arn }
  version    = var.ocp_version
  sts        = local.sts_roles

  # replicas
  replicas = coalesce(var.replicas, local.default_replicas)

  disable_waiting_in_destroy          = false
  wait_for_create_complete            = true
  wait_for_std_compute_nodes_complete = true

  depends_on = [module.network, module.account_roles_hcp, module.operator_roles_hcp]

}

locals {
  cluster_id                = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].id : rhcs_cluster_rosa_classic.rosa[0].id
  cluster_name              = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].name : rhcs_cluster_rosa_classic.rosa[0].name
  cluster_oidc_config_id    = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].sts.oidc_config_id : rhcs_cluster_rosa_classic.rosa[0].sts.oidc_endpoint_url
  cluster_oidc_endpoint_url = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].sts.oidc_config_id : rhcs_cluster_rosa_classic.rosa[0].sts.oidc_endpoint_url
  cluster_api_url           = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].api_url : rhcs_cluster_rosa_classic.rosa[0].api_url
  cluster_console_url       = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].console_url : rhcs_cluster_rosa_classic.rosa[0].console_url
}
