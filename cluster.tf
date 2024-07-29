data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "rhcs_versions" "classic_versions" {
  search = "enabled='t' and rosa_enabled='t' and channel_group='stable'"
  order = "id"
}

data "rhcs_versions" "hcp_versions" {
  search = "enabled='t' and rosa_enabled='t' and hosted_control_plane_enabled = 't' and channel_group='stable'"
  order = "id"
}


#
# cluster
#
locals {
  # networking
  subnet_ids = var.private ? module.network.private_subnet_ids : concat(module.network.private_subnet_ids, module.network.public_subnet_ids)

  # autoscaling
  autoscaling = var.max_replicas != null
  replicas    = var.replicas == null ? var.multi_az ? 3 : 2 : var.replicas

  # version
  classic_version = var.ocp_version == null ? var.ocp_version : element(data.rhcs_versions.classic_versions.items,length(data.rhcs_versions.classic_versions.items)-1).name
  hcp_version = var.ocp_version == null ? var.ocp_version : element(data.rhcs_versions.hcp_versions.items,length(data.rhcs_versions.hcp_versions.items)-1).name
}

resource "validation_warning" "autoscaling_variable_deprecation" {
  condition = var.autoscaling != null
  summary   = "The 'autoscaling' variable will be deprecated in a future release.'"
  details   = <<EOF
Please use 'replicas' with 'max_replicas' to enable autoscaling for ROSA Classic clusters.  Setting 'max_replicas'
will enable the autoscaling feature.
EOF
}



# classic
resource "rhcs_cluster_rosa_classic" "rosa" {
  count = var.hosted_control_plane ? 0 : 1

  name = var.cluster_name

  # aws
  cloud_region   = var.region
  aws_account_id = data.aws_caller_identity.current.account_id
  tags           = var.tags

  # autoscaling and instance settings
  compute_machine_type = var.compute_machine_type
  autoscaling_enabled  = local.autoscaling
  min_replicas         = local.autoscaling ? local.replicas : null
  max_replicas         = local.autoscaling ? var.max_replicas : null
  replicas             = local.autoscaling ? null : coalesce(var.replicas, local.replicas)

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
  version    = local.classic_version
  sts        = local.sts_roles

  disable_waiting_in_destroy = false
  wait_for_create_complete   = true

  depends_on = [module.network, module.account_roles_classic, module.operator_roles_classic]

  lifecycle {
    precondition {
      condition     = var.max_replicas != null ? var.max_replicas >= local.replicas : true
      error_message = "'max_replicas' must be greater than or equal to 'replicas' when set."
    }

    precondition {
      condition     = var.multi_az ? (local.replicas % 3 == 0) : (local.replicas % 2 == 0)
      error_message = "'replicas' must be divisible by 3 when 'multi_az' is set and 2 when it is not set."
    }
  }
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

  # autoscaling and instance settings
  compute_machine_type = var.compute_machine_type
  replicas             = coalesce(var.replicas, local.replicas)

  # network
  private            = var.private
  aws_subnet_ids     = local.subnet_ids
  machine_cidr       = var.vpc_cidr
  availability_zones = module.network.private_subnet_azs
  pod_cidr           = var.pod_cidr
  service_cidr       = var.service_cidr

  # rosa / openshift
  properties = { rosa_creator_arn = data.aws_caller_identity.current.arn }
  version    = local.hcp_version
  sts        = local.sts_roles

  disable_waiting_in_destroy          = false
  wait_for_create_complete            = true
  wait_for_std_compute_nodes_complete = true

  depends_on = [module.network, module.account_roles_hcp, module.operator_roles_hcp]
  lifecycle {
    precondition {
      condition     = var.multi_az ? (local.replicas % 3 == 0) : (local.replicas % 2 == 0)
      error_message = "'replicas' must be divisible by 3 when 'multi_az' is set and 2 when it is not set."
    }
  }
}

locals {
  cluster_id                = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].id : rhcs_cluster_rosa_classic.rosa[0].id
  cluster_name              = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].name : rhcs_cluster_rosa_classic.rosa[0].name
  cluster_oidc_config_id    = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].sts.oidc_config_id : rhcs_cluster_rosa_classic.rosa[0].sts.oidc_config_id
  cluster_oidc_endpoint_url = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].sts.oidc_endpoint_url : rhcs_cluster_rosa_classic.rosa[0].sts.oidc_endpoint_url
  cluster_api_url           = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].api_url : rhcs_cluster_rosa_classic.rosa[0].api_url
  cluster_console_url       = var.hosted_control_plane ? rhcs_cluster_rosa_hcp.rosa[0].console_url : rhcs_cluster_rosa_classic.rosa[0].console_url
}
