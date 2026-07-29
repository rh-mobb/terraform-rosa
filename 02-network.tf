check "pre_existing_subnets" {
  assert {
    condition     = length(var.private_subnet_ids) == length(var.public_subnet_ids)
    error_message = "'private_subnet_ids' and 'public_subnet_ids' must contain the same number of subnets."
  }
}

module "network" {
  source = "./modules/terraform-rosa-networking"

  cluster_name = var.cluster_name

  network = {
    private_link       = var.private
    multi_az           = var.multi_az
    vpc_network        = split("/", var.vpc_cidr)[0]
    vpc_cidr_size      = tonumber(split("/", var.vpc_cidr)[1])
    subnet_cidr_size   = var.subnet_cidr_size
    public_subnet_ids  = var.public_subnet_ids
    private_subnet_ids = var.private_subnet_ids
  }

  tags = var.tags
}
