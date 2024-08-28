terraform {
  required_providers {
    rhcs = {
      source = "terraform-redhat/rhcs"
      version = "1.6.3-prerelease.2"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.64.0"
    }
    validation = {
      source  = "tlkamp/validation"
      version = "1.1.1"
    }
  }
}

provider "rhcs" {
  token = var.token
}

provider "aws" {
  region = var.region
}
