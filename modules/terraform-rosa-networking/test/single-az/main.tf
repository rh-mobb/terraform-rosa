provider "aws" {
  region = "us-east-1"
}

module "test" {
  source = "../../"

  cluster_name = "dscott-small"

  network = {
    private_link       = false
    multi_az           = true
    vpc_network        = "10.10.0.0"
    vpc_cidr_size      = 23
    private_subnet_ids = []
    public_subnet_ids  = []
    subnet_cidr_size   = 26
  }

  tags = {
    "cost-center"   = "CC468"
    "service-phase" = "lab"
    "app-code"      = "MOBB-001"
    "owner"         = "dscott_redhat.com"
    "provisioner"   = "Terraform"
  }
}

output "output" {
  value = module.test
}
