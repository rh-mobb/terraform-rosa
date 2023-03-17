terraform {
  required_providers {
    ocm = {
      source  = "terraform-redhat/ocm"
      version = "0.0.2"
    }
  }
}

provider "ocm" {
  token = var.token
}
