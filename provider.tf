terraform {
  required_providers {
    rhcs = {
      version = ">= 1.6.9"
      source  = "terraform-redhat/rhcs"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }

    validation = {
      source  = "tlkamp/validation"
      version = "1.1.1"
    }
  }
}

provider "rhcs" {
  token = var.token
  url   = var.govcloud ? "https://api.openshiftusgov.com" : "https://api.openshift.com"
  token_url = var.govcloud ? "https://sso.openshiftusgov.com/realms/redhat-external/protocol/openid-connect/token" : "https://sso.redhat.com/realms/redhat-external/protocol/openid-connect/token"
  client_id = var.govcloud ? "console-dot" : "cloud-services"
  client_secret = ""
}

provider "aws" {
  region = var.region
}
