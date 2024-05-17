output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "public_subnet_azs" {
  value = module.network.public_subnet_azs
}

output "private_subnet_azs" {
  value = module.network.private_subnet_azs
}

output "oidc_config_id" {
  value = local.cluster_oidc_config_id
}

output "oidc_endpoint_url" {
  value = local.cluster_oidc_endpoint_url
}

output "cluster_api_url" {
  value = local.cluster_api_url
}
