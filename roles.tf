#
# iam account roles
#
locals {
  openshift_major_version = join(".", slice(split(".", var.ocp_version), 0, 2))
}

data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

#
# iam account roles
#

# classic
module "account_roles" {
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.15"

  create_operator_roles = false
  create_oidc_provider  = false
  create_account_roles  = true

  account_role_prefix    = var.cluster_name
  ocm_environment        = "production"
  rosa_openshift_version = local.openshift_major_version
  account_role_policies  = data.rhcs_policies.all_policies.account_role_policies
  operator_role_policies = data.rhcs_policies.all_policies.operator_role_policies
  all_versions           = data.rhcs_versions.all
  tags                   = var.tags
}

# hosted control plane
module "account_roles_hcp" {
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources"
  version = "1.6.1-prerelease.2"

  account_role_prefix = var.cluster_name
  tags                = var.tags
}

#
# iam operator roles and oidc provider
#

# classic
data "rhcs_rosa_operator_roles" "operator_roles" {
  count = var.hosted_control_plane ? 0 : 1

  operator_role_prefix = local.cluster_name
  account_role_prefix  = local.cluster_name
}

module "operator_roles" {
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.15"

  create_operator_roles = true
  create_oidc_provider  = true
  create_account_roles  = false

  cluster_id                  = local.cluster_id
  rh_oidc_provider_thumbprint = rhcs_cluster_rosa_classic.rosa[0].sts.thumbprint
  rh_oidc_provider_url        = rhcs_cluster_rosa_classic.rosa[0].sts.oidc_endpoint_url
  operator_roles_properties   = data.rhcs_rosa_operator_roles.operator_roles[0].operator_iam_roles
  tags                        = var.tags
}

# hosted control plane
module "oidc_config_and_provider" {
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-and-provider"
  version = "1.6.1-prerelease.2"

  managed = true
  tags    = var.tags
}

module "operator_roles_hcp" {
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/operator-roles"
  version = "1.6.1-prerelease.2"

  oidc_endpoint_url    = module.oidc_config_and_provider[0].oidc_endpoint_url
  operator_role_prefix = var.cluster_name
  tags                 = var.tags
}

#
# sts role block
#   NOTE: this is the sts role black that is passed into the cluster creation process
#
locals {
  role_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}"

  # account roles
  installer_role_arn = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Installer-Role" : "${local.role_prefix}-Installer-Role"
  support_role_arn   = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Support-Role" : "${local.role_prefix}-Support-Role"

  # instance roles
  master_role_arn = var.hosted_control_plane ? null : "${local.role_prefix}-Support-Role"
  worker_role_arn = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Worker-Role" : "${local.role_prefix}-Worker-Role"

  # oidc config
  oidc_config_id    = var.hosted_control_plane ? module.oidc_config_and_provider[0].oidc_config_id : null
  oidc_endpoint_url = var.hosted_control_plane ? module.oidc_config_and_provider[0].oidc_endpoint_url : null

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
