output "vpc_id" {
  value = module.network.vpc_id
}

output "vpc_cidr" {
  value = module.network.vpc_cidr
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

output "private_route_table_ids" {
  value = module.network.private_route_table_ids
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

output "cluster_console_url" {
  value = local.cluster_console_url
}

output "cluster_id" {
  value = local.cluster_id
}

output "cluster_name" {
  value = local.cluster_name
}

output "region" {
  value = var.region
}

output "bastion_instance_id" {
  value = var.private ? aws_instance.bastion_host[0].id : null
}

output "bastion_public_ip" {
  value = (var.private && var.bastion_public_ip) ? aws_instance.bastion_host[0].public_ip : null
}
output "bastion_connectivity" {
  value = local.bastion_output
}