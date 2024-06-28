# Summary

This repository can be used as a module to create a ROSA cluster with the following components:

- ROSA networking in either private/public architecture
- ROSA cluster in either [Classic](https://docs.openshift.com/rosa/architecture/rosa-architecture-models.html#rosa-classic-architecture_rosa-architecture-models) 
or [Hosted Control Plane](https://docs.openshift.com/rosa/architecture/rosa-architecture-models.html#rosa-hcp-architecture_rosa-architecture-models) architecture
- [Default machine pool](https://docs.openshift.com/rosa/rosa_cluster_admin/rosa_nodes/rosa-nodes-machinepools-about.html) with desired replica count
- Local HTPasswd [identity provider](https://docs.openshift.com/rosa/authentication/sd-configuring-identity-providers.html) with an "admin" user with Cluster Admin privileges
- Local HTPasswd [identity provider](https://docs.openshift.com/rosa/authentication/sd-configuring-identity-providers.html) with an "developer" user with basic privileges


# Usage

The following Terraform is an example file to deploy a public ROSA cluster via this module.  This file
can be created wherever you would like to run Terraform from as a `main.tf` file.  A complete list of variables
and modifications is available via the [variables.tf](variables.tf) file:

**NOTE:** this is an overly simplistic file to demonstrate a simple installation.  You will need to tailor your 
automation to your needs.  If there is functionality that is missing that you would like to see, please open an issue!

```
variable "token" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "developer_password" {
  type      = string
  sensitive = true
}

module "rosa_public" {
  source = "git::https://github.com/rh-mobb/terraform-rosa.git?ref=main"

  hosted_control_plane = false
  private              = false
  multi_az             = false
  replicas             = 2
  max_replicas         = 4
  cluster_name         = "my-rosa-cluster"
  ocp_version          = "4.15.14"
  token                = var.token
  admin_password       = var.admin_password
  developer_password   = var.developer_password
  pod_cidr             = "10.128.0.0/14"
  service_cidr         = "172.30.0.0/16"
  compute_machine_type = "m5.xlarge"

  tags = {
    "owner" = "me"
  }
}
```

Once the above has been created, normal Terraform commands can be run:

```bash
terraform init
terraform plan rosa.out
terraform apply rosa.out
```
