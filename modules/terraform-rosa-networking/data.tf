data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [data.aws_region.current.name]
  }

  filter {
    name   = "group-name"
    values = [data.aws_region.current.name]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
