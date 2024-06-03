variable "cluster_name" {
  description = "Name of the cluster to create"
  type        = string
  default     = "dscott"
}

# TODO: no validation on this input currently
variable "network" {
  description = "Cluster networking variables"
  type = object({
    private_link       = bool
    multi_az           = bool
    vpc_network        = string
    vpc_cidr_size      = number
    private_subnet_ids = list(string)
    public_subnet_ids  = list(string)
    subnet_cidr_size   = number
  })
  default = {
    private_link       = false
    multi_az           = false
    vpc_network        = "10.10.0.0"
    vpc_cidr_size      = 16
    private_subnet_ids = []
    public_subnet_ids  = []
    subnet_cidr_size   = 20
  }

  validation {
    condition     = (length(var.network.public_subnet_ids) == 0 && length(var.network.private_subnet_ids) == 0) || (length(var.network.public_subnet_ids) > 0 && length(var.network.private_subnet_ids) > 0)
    error_message = "Public/Private subnets must either both be specified or omitted.  Found private: [${length(var.network.private_subnet_ids)}], public: [${length(var.network.public_subnet_ids)}]."
  }
}

variable "tags" {
  description = "Tags applied to all objects"
  type        = map(string)
  default     = {}
}
