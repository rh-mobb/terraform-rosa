locals {
  bastion_tags = merge(var.tags, { "Name" = "${var.cluster_name}-bastion" })
}

data "aws_ami" "rhel9" {
  count = var.private ? 1 : 0

  executable_users = ["self"]
  owners           = ["309956199498"]
  most_recent      = true

  filter {
    name   = "name"
    values = ["RHEL-9*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "bastion_host" {
  count = var.private ? 1 : 0

  key_name   = "${var.cluster_name}-bastion"
  public_key = file(var.bastion_public_ssh_key)

  tags = local.bastion_tags
}

resource "aws_security_group" "bastion_host" {
  count = var.private ? 1 : 0

  description = "Security group for Bastion access"
  name        = "${var.cluster_name}-bastion"
  vpc_id      = module.network.vpc_id

  # TODO: we technically should not need this if we are using sshuttle
  ingress {
    description = "Bastion SSH Ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Bastion Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.bastion_tags
}

resource "aws_instance" "bastion_host" {
  count = var.private ? 1 : 0

  ami                    = data.aws_ami.rhel9[0].id
  instance_type          = "t2.micro"
  subnet_id              = module.network.private_subnet_ids[0]
  key_name               = aws_key_pair.bastion_host[0].key_name
  vpc_security_group_ids = [aws_security_group.bastion_host[0].id]

  tags = local.bastion_tags

  user_data = <<EOF
#!/bin/bash
set -e -x

sudo dnf install -y wget curl python36 python36-devel net-tools gcc libffi-devel openssl-devel jq bind-utils podman

# ssm
sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# openshift/kubernetes clients
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
mkdir openshift
tar -zxvf openshift-client-linux.tar.gz -C openshift
sudo install openshift/oc /usr/local/bin/oc
sudo install openshift/kubectl /usr/local/bin/kubectl
EOF
}
