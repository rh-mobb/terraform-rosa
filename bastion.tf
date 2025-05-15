locals {
  bastion_tags   = merge(var.tags, { "Name" = "${var.cluster_name}-bastion" })
  bastion_subnet = var.bastion_public_ip ? module.network.public_subnet_ids[0] : module.network.private_subnet_ids[0]
  bastion_ssh    = <<EOF
You can SSH to your bastion via

    ssh ec2-user@${(var.private && var.bastion_public_ip) ? aws_instance.bastion_host[0].public_ip : ""}
    or
    sshuttle --remote ec2-user@${(var.private && var.bastion_public_ip) ? aws_instance.bastion_host[0].public_ip : ""}--dns ${var.vpc_cidr}
EOF
  bastion_ssm    = <<EOF
Congratulations on securely deploying your bastion to a private subnet with no public internet ingress!

It's so secure you can't even SSH to it.

Uhhh so how do I access my cluster?  Glad you asked!

1. Install the AWS Session Manager Plugin for the AWS CLI

    - https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

2. Install sshuttle

    - For mac `brew install sshuttle`
    - Otherwise - https://sshuttle.readthedocs.io/en/stable/installation.html

3. Create an SSH VPN over AWS Session Manager

    sshuttle --ssh-cmd="ssh -o ProxyCommand='sh -c \"aws --region ${var.region} ssm start-session --target %h --document-name AWS-StartSSHSession --parameters \
    portNumber=22\"'" --remote ec2-user@${(var.private && !var.bastion_public_ip) ? aws_instance.bastion_host[0].id : ""} --dns ${var.vpc_cidr}
EOF
  bastion_output = var.private ? (var.bastion_public_ip ? local.bastion_ssh : local.bastion_ssm) : null
}

resource "aws_iam_instance_profile" "bastion_iam_profile" {
  count = var.private ? 1 : 0
  name  = "${var.cluster_name}-bastion-ec2_profile"
  role  = aws_iam_role.bastion_iam_role[0].name
}

resource "aws_iam_role" "bastion_iam_role" {
  count       = var.private ? 1 : 0
  name        = "${var.cluster_name}-bastion-iam-role"
  description = "The role for the bastion EC2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_iam_ssm_policy" {
  count      = var.private ? 1 : 0
  role       = aws_iam_role.bastion_iam_role[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_ami" "rhel9" {
  count = var.private ? 1 : 0

  # executable_users = ["self"]
  owners           = ["309956199498", "219670896067"]
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

  ami                         = data.aws_ami.rhel9[0].id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.bastion_iam_profile[0].name
  subnet_id                   = local.bastion_subnet
  associate_public_ip_address = var.bastion_public_ip
  key_name                    = aws_key_pair.bastion_host[0].key_name
  vpc_security_group_ids      = [aws_security_group.bastion_host[0].id]

  tags = local.bastion_tags

  user_data = <<EOF
#!/bin/bash
set -e -x

# ssm
sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# useful system packages
sudo dnf install -y wget curl python3.12 python3.12-devel net-tools gcc libffi-devel openssl-devel jq bind-utils podman

# openshift/kubernetes clients
wget -q https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
mkdir openshift
tar -zxvf openshift-client-linux.tar.gz -C openshift
sudo install openshift/oc /usr/local/bin/oc
sudo install openshift/kubectl /usr/local/bin/kubectl
EOF
}
