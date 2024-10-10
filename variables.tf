variable "private" {
  description = "Set to true to provision a private cluster, which restricts access from the public internet."
  type        = bool
  default     = false
}

variable "bastion_public_ssh_key" {
  description = <<EOF
  Location to an SSH public key file on the local system which is used to provide connectivity to the bastion host
  when the 'private' variable is set to 'true'.
  EOF
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "bastion_public_ip" {
  description = "Should the Bastion have a public ip?"
  type        = bool
  default     = false
}

variable "bastion_cidr_blocks" {
  description = "CIDR blocks for Bastion SSH Ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "use_sshuttle" {
  description = "Set to true to use sshuttle and skip creating security group for SSH access."
  type        = bool
  default     = true
}

variable "aws_billing_account_id" {
  description = "The AWS billing account identifier where all resources are billed. If no information is provided, the data will be retrieved from the currently connected account."
  type        = string
  default     = null
}

variable "region" {
  description = "The AWS region to provision a ROSA cluster and required components into."
  type        = string
  default     = "us-east-1"
}

variable "multi_az" {
  description = <<EOF
  Configure the cluster to use a highly available, multi availability zone configuration.  It should be noted that use
  of the 'multi_az' variable may affect minimum requirements for 'replicas' and may restrict regions that do not have
  three availability zones.
  EOF
  type        = bool
  default     = false
}

variable "hosted_control_plane" {
  description = "Provision a ROSA cluster using a Hosted Control Plane."
  type        = bool
  default     = false
}

variable "autoscaling" {
  description = <<EOF
  Enable autoscaling for the default machine pool, this is ignored for HCP clusters as autoscaling is not supported
  for Hosted Control Plane clusters at this time.

  WARN: this variable is deprecated.  Simply setting 'max_replicas' will enable autoscaling.  This will be removed
  in a future version of this module.
  EOF
  type        = bool
  nullable    = true
  default     = null
}

variable "replicas" {
  description = <<EOF
  Minimum number of replicas for the default machine pool.  If unset, a default value is configured based on the
  'multi_az' value.
  EOF
  type        = number
  nullable    = true
  default     = null
}

variable "max_replicas" {
  description = <<EOF
  Maximum number of replicas for the default machine pool.  If set, autoscaling is enabled for classic clusters.
  Autoscaling is unsupported via Terraform for HCP clusters, so this value is always ignored when 'hosted_control_plane'
  is set to 'true'.  This value must be equal to or higher than the 'replicas' value if set.
  EOF
  type        = number
  nullable    = true
  default     = null
}

variable "token" {
  description = <<EOF
  OCM token used to authenticate against the OpenShift Cluster Manager API.  See
  https://console.redhat.com/openshift/token/rosa/show to access your token.
  EOF
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "The name of the cluster.  This is also used as a prefix to name related components."
  type        = string
}

variable "ocp_version" {
  description = <<EOF
  The version of OpenShift to use.  You can use the command 'rosa list versions' to see all available OpenShift
  versions available to ROSA.
  EOF
  type        = string
  # default     = "4.15.18"
  default = null
}

variable "vpc_cidr" {
  description = "The CIDR of the VPC that will be created."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr_size" {
  description = <<EOF
  The CIDR size of each of the individual subnets that will be created.  Must be within range of the 'vpc_cidr'
  variable.
  EOF
  type        = number
  default     = 20
}

variable "pod_cidr" {
  description = "The internal pod CIDR network used for assigning IP addresses to pods."
  type        = string
  default     = "10.128.0.0/14"
}

variable "service_cidr" {
  description = "The internal service CIDR network used for assigning IP addresses to services."
  type        = string
  default     = "172.30.0.0/16"
}

variable "tags" {
  description = "Tags applied to all objects."
  type        = map(string)
  default     = {}
}

variable "admin_password" {
  description = <<EOF
  Password for the 'admin' user. IDP is not created if unspecified.  Password must be 14 characters or more, contain
  one uppercase letter and a symbol or number.
  EOF
  type        = string
  sensitive   = true
}

variable "developer_password" {
  description = <<EOF
  Password for the 'developer' user. IDP is not created if unspecified.  Password must be 14 characters or more, contain
  one uppercase letter and a symbol or number.
  EOF
  type        = string
  sensitive   = true
}

variable "compute_machine_type" {
  description = <<EOF
  The machine type used by the initial worker nodes, for example, m5.xlarge.  You can use the command 'rosa list
  instance-types' to see all available instance types available to ROSA.
  EOF
  type        = string
  default     = "m5.xlarge"
}
