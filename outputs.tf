#
# networking outputs
#
output "vpc_id" {
  value = local.vpc_id
}

output "vpc_cidr" {
  value = var.vpc_cidr
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "public_subnet_azs" {
  value = local.availability_zones
}

output "private_subnet_azs" {
  value = local.availability_zones
}

output "private_route_table_ids" {
  value = local.private_route_table_ids
}

output "public_route_table_ids" {
  value = local.public_route_table_ids
}

#
# oidc outputs
#
output "oidc_config_id" {
  value = local.cluster_oidc_config_id
}

output "oidc_endpoint_url" {
  value = local.cluster_oidc_endpoint_url
}

#
# cluster access outputs
#
output "cluster_api_url" {
  value = local.cluster_api_url
}

output "cluster_console_url" {
  value = local.cluster_console_url
}
