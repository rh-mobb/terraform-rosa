variable "cluster_name" {
  default = "dscott-classic"
}

variable "ocp_version" {
  default = "4.15.9"
}

variable "multi_az" {
  default = false
}

variable "token" {
  sensitive = true
}

variable "admin_password" {
  sensitive = true
}

variable "developer_password" {
  sensitive = true
}

module "rosa_public" {
  source = "../"

  hosted_control_plane = false
  private              = false
  multi_az             = var.multi_az
  autoscaling          = true
  cluster_name         = var.cluster_name
  ocp_version          = var.ocp_version
  token                = var.token
  admin_password       = var.admin_password
  developer_password   = var.developer_password
  pod_cidr             = "10.128.0.0/14"
  service_cidr         = "172.30.0.0/16"

  tags = {
    "cost-center"   = "CC468"
    "service-phase" = "lab"
    "app-code"      = "MOBB-001"
    "owner"         = "dscott_redhat.com"
    "provisioner"   = "Terraform"
  }
}

output "rosa_public" {
  value = module.rosa_public
}
