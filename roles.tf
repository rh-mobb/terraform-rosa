#
# iam account roles
#
locals {
  openshift_major_version = join(".", slice(split(".", var.ocp_version), 0, 2))
}

module "account_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.3"

  create_operator_roles = false
  create_oidc_provider  = false
  create_account_roles  = true

  account_role_prefix    = var.cluster_name
  ocm_environment        = "production"
  rosa_openshift_version = local.openshift_major_version
}

#
# iam operator roles and oidc provider
#
data "ocm_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.cluster_name
  account_role_prefix  = var.cluster_name
}

module "operator_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.3"

  create_operator_roles = true
  create_oidc_provider  = true
  create_account_roles  = false

  cluster_id                  = ocm_cluster_rosa_classic.rosa.id
  rh_oidc_provider_thumbprint = ocm_cluster_rosa_classic.rosa.sts.thumbprint
  rh_oidc_provider_url        = ocm_cluster_rosa_classic.rosa.sts.oidc_endpoint_url
  operator_roles_properties   = data.ocm_rosa_operator_roles.operator_roles.operator_iam_roles
}
