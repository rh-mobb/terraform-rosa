data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [data.aws_region.current.id]
  }

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
