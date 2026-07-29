output "private_subnet_ids" {
  value = local.create_networking ? [for net in aws_subnet.rosa_private : net.id] : var.network.private_subnet_ids
}

output "public_subnet_ids" {
  value = local.create_networking ? [for net in aws_subnet.rosa_public : net.id] : var.network.public_subnet_ids
}

output "private_subnet_azs" {
  value = local.create_networking ? [for net in aws_subnet.rosa_private : net.availability_zone] : [for net in data.aws_subnet.private_selected : net.availability_zone]
}

output "public_subnet_azs" {
  value = local.create_networking ? [for net in aws_subnet.rosa_public : net.availability_zone] : [for net in data.aws_subnet.public_selected : net.availability_zone]
}

output "vpc_id" {
  value = local.create_networking ? aws_vpc.rosa[0].id : data.aws_vpc.selected[0].id
}

output "vpc_cidr" {
  value = local.create_networking ? aws_vpc.rosa[0].cidr_block : data.aws_vpc.selected[0].cidr_block
}

output "private_route_table_ids" {
  value = local.create_networking ? aws_route_table.rosa_private[*].id : []
}
