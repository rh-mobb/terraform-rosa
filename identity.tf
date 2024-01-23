resource "rhcs_identity_provider" "admin" {
  count = var.admin_password != null && var.admin_password != "" ? 1 : 0

  cluster = rhcs_cluster_rosa_classic.rosa.id
  name    = "admin"
  htpasswd = {
    users = [{
      username = "admin"
      password = var.admin_password
      },
    ]
  }

  depends_on = [rhcs_cluster_rosa_classic.rosa]
}

resource "rhcs_identity_provider" "developer" {
  count = var.developer_password != null && var.developer_password != "" ? 1 : 0

  cluster = rhcs_cluster_rosa_classic.rosa.id
  name    = "developer"
  htpasswd = {
    users = [{
      username = "developer"
      password = var.developer_password
      },
    ]
  }

  depends_on = [rhcs_cluster_rosa_classic.rosa]
}
