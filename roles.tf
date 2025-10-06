#
# iam account roles
#

# classic
module "account_roles_classic" {
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/account-iam-resources"
  version = "1.7.0"

  account_role_prefix = var.cluster_name
  openshift_version   = local.classic_version
  tags                = var.tags
}

# hosted control plane
module "account_roles_hcp" {
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources"
  version = "1.7.0"

  account_role_prefix = var.cluster_name
  tags                = var.tags
}

#
# iam operator roles and oidc provider
#

# classic
module "oidc_config_and_provider_classic" {
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/oidc-config-and-provider"
  version = "1.7.0"

  managed = true
  tags    = var.tags
}

module "operator_policies_classic" {
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/operator-policies"
  version = "1.7.0"

  account_role_prefix = var.cluster_name
  openshift_version   = local.classic_version
  tags                = var.tags
}

module "operator_roles_classic" {
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/operator-roles"
  version = "1.7.0"

  operator_role_prefix = var.cluster_name
  account_role_prefix  = module.operator_policies_classic[0].account_role_prefix
  oidc_endpoint_url    = module.oidc_config_and_provider_classic[0].oidc_endpoint_url
  tags                 = var.tags
  govcloud             = var.govcloud
}

# hosted control plane
module "oidc_config_and_provider_hcp" {
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-and-provider"
  version = "1.7.0"

  managed = true
  tags    = var.tags
}

module "operator_roles_hcp" {
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/operator-roles"
  version = "1.7.0"

  oidc_endpoint_url    = module.oidc_config_and_provider_hcp[0].oidc_endpoint_url
  operator_role_prefix = var.cluster_name
  tags                 = var.tags
}

#
# sts role block
#   NOTE: this is the sts role block that is passed into the cluster creation process
#
locals {
  role_prefix = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}"

  # account roles
  installer_role_arn = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Installer-Role" : "${local.role_prefix}-Installer-Role"
  support_role_arn   = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Support-Role" : "${local.role_prefix}-Support-Role"

  # instance roles
  master_role_arn = var.hosted_control_plane ? null : "${local.role_prefix}-ControlPlane-Role"
  worker_role_arn = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Worker-Role" : "${local.role_prefix}-Worker-Role"

  # oidc config
  oidc_config_id    = var.hosted_control_plane ? module.oidc_config_and_provider_hcp[0].oidc_config_id : module.oidc_config_and_provider_classic[0].oidc_config_id
  oidc_endpoint_url = var.hosted_control_plane ? module.oidc_config_and_provider_hcp[0].oidc_endpoint_url : module.oidc_config_and_provider_classic[0].oidc_endpoint_url

  # sts roles
  sts_roles = {
    role_arn         = local.installer_role_arn,
    support_role_arn = local.support_role_arn,
    instance_iam_roles = {
      master_role_arn = local.master_role_arn,
      worker_role_arn = local.worker_role_arn
    },
    operator_role_prefix = var.cluster_name,
    oidc_config_id       = local.oidc_config_id
    oidc_endpoint_url    = local.oidc_endpoint_url
  }
}
