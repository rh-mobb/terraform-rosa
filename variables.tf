variable "private" {
  type    = bool
  default = false
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "autoscaling" {
  type    = bool
  default = true
}

variable "token" {
  type      = string
  sensitive = true
}

variable "cluster_name" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ocp_version" {
  type    = string
  default = "4.12.7"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
