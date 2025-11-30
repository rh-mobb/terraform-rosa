resource "aws_vpc" "rosa" {
  # checkov:skip=CKV2_AWS_11:VPC flow logging is optional for development/test environments
  # checkov:skip=CKV2_AWS_12:Default security group is managed by AWS and ROSA, not explicitly configured here
  count = local.create_networking ? 1 : 0

  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags,
    {
      "Name" = var.cluster_name
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
}
