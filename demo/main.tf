terraform {
  required_providers {
    rhcs = {
      version = ">= 1.2.2"
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

variable "cluster_name" {}

variable "token" {}

module "rosa_cluster" {
  source = "../"

  cluster_name = var.cluster_name
  ocp_version  = "4.10.63"
  region       = "us-east-1"
  token        = var.token
}
