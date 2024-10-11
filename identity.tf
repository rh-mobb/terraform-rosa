locals {
  # admin idp
  admin_username = "admin"
  admin_group    = "cluster-admins"

  # developer idp
  developer_username = "developer"
}

resource "rhcs_identity_provider" "admin" {
  cluster = local.cluster_id
  name    = local.admin_username
  htpasswd = {
    users = [{
      username = local.admin_username
      password = var.admin_password
    }]
  }
}

resource "rhcs_identity_provider" "developer" {

  cluster = local.cluster_id
  name    = local.developer_username
  htpasswd = {
    users = [{
      username = local.developer_username
      password = var.developer_password
    }]
  }
}

resource "rhcs_group_membership" "admin" {
  user    = rhcs_identity_provider.admin.htpasswd.users[0].username
  group   = local.admin_group
  cluster = local.cluster_id
}
