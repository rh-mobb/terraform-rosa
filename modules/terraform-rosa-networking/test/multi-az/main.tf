provider "aws" {
  region = "us-east-2"
}

module "test" {
  source = "../../"

  cluster_name = "dscott-multi"

  network = {
    private_link       = true
    multi_az           = true
    vpc_network        = "10.20.0.0"
    vpc_cidr_size      = 16
    private_subnet_ids = []
    public_subnet_ids  = []
    subnet_cidr_size   = 20
  }
}
