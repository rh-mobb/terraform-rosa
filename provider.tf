terraform {
  required_providers {
    rhcs = {
      version = ">= 1.7.0"
      source  = "terraform-redhat/rhcs"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.7.0"
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
