#
# iam account roles
#
locals {
  openshift_major_version = join(".", slice(split(".", var.ocp_version), 0, 2))
}

data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

module "account_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.12"

  create_operator_roles = false
  create_oidc_provider  = false
  create_account_roles  = true

  account_role_prefix    = var.cluster_name
  ocm_environment        = "production"
  rosa_openshift_version = local.openshift_major_version
  account_role_policies  = data.rhcs_policies.all_policies.account_role_policies
  operator_role_policies = data.rhcs_policies.all_policies.operator_role_policies
  all_versions           = data.rhcs_versions.all
  tags                   = local.tags
}

#
# iam operator roles and oidc provider
#
data "rhcs_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = rhcs_cluster_rosa_classic.rosa.name
  account_role_prefix  = rhcs_cluster_rosa_classic.rosa.name
}

module "operator_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.12"

  create_operator_roles = true
  create_oidc_provider  = true
  create_account_roles  = false

  cluster_id                  = rhcs_cluster_rosa_classic.rosa.id
  rh_oidc_provider_thumbprint = rhcs_cluster_rosa_classic.rosa.sts.thumbprint
  rh_oidc_provider_url        = rhcs_cluster_rosa_classic.rosa.sts.oidc_endpoint_url
  operator_roles_properties   = data.rhcs_rosa_operator_roles.operator_roles.operator_iam_roles
}
