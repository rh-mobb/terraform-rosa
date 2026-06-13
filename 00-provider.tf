terraform {
  required_version = ">= 1.5.0"

  required_providers {
    rhcs = {
      source  = "terraform-redhat/rhcs"
      version = ">= 1.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "rhcs" {
  token         = var.token
  url           = var.govcloud ? "https://api.openshiftusgov.com" : "https://api.openshift.com"
  token_url     = var.govcloud ? "https://sso.openshiftusgov.com/auth/realms/redhat-external/protocol/openid-connect/token" : "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token"
  client_id     = var.client_id != null ? var.client_id : var.govcloud ? "console-dot" : "cloud-services"
  client_secret = var.client_secret != null ? var.client_secret : ""
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}