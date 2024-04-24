variable "private" {
  type    = bool
  default = false
}

variable "bastion_public_ssh_key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "hosted_control_plane" {
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

variable "ocp_version" {
  type    = string
  default = "4.14.7"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "subnet_cidr_size" {
  type    = number
  default = 20
}

variable "pod_cidr" {
  type    = string
  default = "10.128.0.0/14"
}

variable "service_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "tags" {
  description = "Tags applied to all objects"
  type        = map(string)
  default = {
    "owner" = "dscott"
  }
}

variable "admin_password" {
  description = "Password for the 'admin' user. IDP is not created if unspecified."
  type        = string
  sensitive   = true
}

variable "developer_password" {
  description = "Password for the 'developer' user. IDP is not created if unspecified."
  type        = string
  sensitive   = true
}

variable "region" {
  type    = string
  default = "us-east-1"
}
