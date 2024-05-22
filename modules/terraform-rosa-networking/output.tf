output "private_subnet_ids" {
  value = length(var.network.private_subnet_ids) > 0 ? var.network.private_subnet_ids : [for net in aws_subnet.rosa_private : net.id]
}

output "public_subnet_ids" {
  value = length(var.network.public_subnet_ids) > 0 ? var.network.public_subnet_ids : [for net in aws_subnet.rosa_public : net.id]
}

output "private_subnet_azs" {
  value = length(var.network.private_subnet_ids) > 0 ? [] : [for net in aws_subnet.rosa_private : net.availability_zone]
}

output "public_subnet_azs" {
  value = length(var.network.public_subnet_ids) > 0 ? [] : [for net in aws_subnet.rosa_public : net.availability_zone]
}

output "vpc_id" {
  value = aws_vpc.rosa[0].id
}

output "vpc_cidr" {
  value = aws_vpc.rosa[0].cidr_block
}

output "private_route_table_ids" {
  value = aws_route_table.rosa_private[*].id
}
