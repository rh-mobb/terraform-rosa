variable "private" {
  type    = bool
  default = false
}

variable "bastion_public_ssh_key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "region" {
  type    = string
  default = "us-east-1"
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
  description = "Enable autoscaling for the default machine pool, this is ignored for HCP clusters"
}

variable "replicas" {
  type = number
  nullable = true
  default = null
  description = "Number of replicas for the default machine pool, this is ignored if autoscaling is enabled"
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
  default     = {}
}

variable "admin_password" {
  description = <<EOF
  Password for the 'admin' user. IDP is not created if unspecified.

  Password must be 14 characters or more, contain one uppercase letter and a symbol or number.
  EOF
  type        = string
  sensitive   = true
}

variable "developer_password" {
  description = <<EOF
  Password for the 'developer' user. IDP is not created if unspecified.

  Password must be 14 characters or more, contain one uppercase letter and a symbol or number.
  EOF
  type        = string
  sensitive   = true
}

variable "compute_machine_type" {
  description = "The machine type used by the initial worker nodes, for example, m5.xlarge."
  type        = string
  default     = "m5.xlarge" # or any other default value you prefer
}

