terraform {
  required_providers {
    ocm = {
      source  = "terraform-redhat/ocm"
      version = "0.0.2"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
  }
}

provider "ocm" {
  token = var.token
}
