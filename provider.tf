terraform {
  required_providers {
    rhcs = {
      version = ">= 1.4.0-prerelease.1"
      source  = "terraform-redhat/rhcs"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
  }
}

provider "rhcs" {
  token = var.token
}
