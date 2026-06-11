output "vpc_id" {
  description = "The ID of the VPC created for the ROSA cluster"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "public_subnet_azs" {
  description = "List of availability zones for public subnets"
  value       = module.network.public_subnet_azs
}

output "private_subnet_azs" {
  description = "List of availability zones for private subnets"
  value       = module.network.private_subnet_azs
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.network.private_route_table_ids
}

output "oidc_config_id" {
  description = "The ID of the OIDC configuration"
  value       = local.cluster_oidc_config_id
}

output "oidc_endpoint_url" {
  description = "The OIDC endpoint URL"
  value       = local.cluster_oidc_endpoint_url
}

output "cluster_api_url" {
  description = "The API URL for the ROSA cluster"
  value       = local.cluster_api_url
}

output "cluster_console_url" {
  description = "The console URL for the ROSA cluster"
  value       = local.cluster_console_url
}

output "cluster_id" {
  description = "The ID of the ROSA cluster"
  value       = local.cluster_id
}

output "cluster_name" {
  description = "The name of the ROSA cluster"
  value       = local.cluster_name
}

output "region" {
  description = "The AWS region where the cluster is deployed"
  value       = var.region
}

output "bastion_instance_id" {
  description = "The instance ID of the bastion host (only set for private clusters)"
  value       = var.private ? aws_instance.bastion_host[0].id : null
}

output "bastion_public_ip" {
  description = "The public IP address of the bastion host (only set for private clusters with public IP enabled)"
  value       = (var.private && var.bastion_public_ip) ? aws_instance.bastion_host[0].public_ip : null
}

output "bastion_connectivity" {
  description = "Instructions for connecting to the bastion host (only set for private clusters)"
  value       = local.bastion_output
}

output "karpenter_role_arn" {
  description = "The ARN of the Karpenter IAM role (only set when karpenter = true)"
  value       = var.hosted_control_plane && var.karpenter ? aws_iam_role.karpenter[0].arn : null
}