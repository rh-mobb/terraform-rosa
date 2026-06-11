#
# iam account roles
#

# classic
module "account_roles_classic" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/account-iam-resources"
  version = "~> 1.7"

  account_role_prefix = var.cluster_name
  openshift_version   = local.classic_version
  tags                = var.tags
}

# hosted control plane
module "account_roles_hcp" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources"
  version = "~> 1.7"

  account_role_prefix = var.cluster_name
  tags                = var.tags
}

#
# iam operator roles and oidc provider
#

# classic
module "oidc_config_and_provider_classic" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/oidc-config-and-provider"
  version = "~> 1.7"

  managed = true
  tags    = var.tags
}

# checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
module "operator_policies_classic" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/operator-policies"
  version = "~> 1.7"

  account_role_prefix = var.cluster_name
  openshift_version   = local.classic_version
  tags                = var.tags
}

# checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
module "operator_roles_classic" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 0 : 1

  source  = "terraform-redhat/rosa-classic/rhcs//modules/operator-roles"
  version = "~> 1.7"

  operator_role_prefix = var.cluster_name
  account_role_prefix  = module.operator_policies_classic[0].account_role_prefix
  oidc_endpoint_url    = module.oidc_config_and_provider_classic[0].oidc_endpoint_url
  tags                 = var.tags
  govcloud             = var.govcloud
}

# hosted control plane
module "oidc_config_and_provider_hcp" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-and-provider"
  version = "~> 1.7"

  managed = true
  tags    = var.tags
}

# checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
module "operator_roles_hcp" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane ? 1 : 0

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/operator-roles"
  version = "~> 1.7"

  oidc_endpoint_url    = module.oidc_config_and_provider_hcp[0].oidc_endpoint_url
  operator_role_prefix = var.cluster_name
  tags                 = var.tags
}

#
# sts role block
#   NOTE: this is the sts role block that is passed into the cluster creation process
#
locals {
  role_prefix = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}"

  # account roles
  installer_role_arn = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Installer-Role" : "${local.role_prefix}-Installer-Role"
  support_role_arn   = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Support-Role" : "${local.role_prefix}-Support-Role"

  # instance roles
  master_role_arn = var.hosted_control_plane ? null : "${local.role_prefix}-ControlPlane-Role"
  worker_role_arn = var.hosted_control_plane ? "${local.role_prefix}-HCP-ROSA-Worker-Role" : "${local.role_prefix}-Worker-Role"

  # oidc config
  oidc_config_id    = var.hosted_control_plane ? module.oidc_config_and_provider_hcp[0].oidc_config_id : module.oidc_config_and_provider_classic[0].oidc_config_id
  oidc_endpoint_url = var.hosted_control_plane ? module.oidc_config_and_provider_hcp[0].oidc_endpoint_url : module.oidc_config_and_provider_classic[0].oidc_endpoint_url

  # sts roles
  sts_roles = {
    role_arn         = local.installer_role_arn,
    support_role_arn = local.support_role_arn,
    instance_iam_roles = {
      master_role_arn = local.master_role_arn,
      worker_role_arn = local.worker_role_arn
    },
    operator_role_prefix = var.cluster_name,
    oidc_config_id       = local.oidc_config_id
    oidc_endpoint_url    = local.oidc_endpoint_url
  }

  # karpenter
  #   NOTE: the OIDC endpoint URL may include an "https://" prefix depending on the module version — trimprefix
  #         ensures the condition variable and federated identifier are always in the bare hostname/path format
  #         expected by AWS IAM (e.g. "oidc.op1.openshiftapps.com/<id>").
  karpenter_oidc_url = trimprefix(local.oidc_endpoint_url, "https://")
}

#
# karpenter (autonode) iam role
#   NOTE: only created when both hosted_control_plane and karpenter are true.
#

data "aws_iam_policy_document" "karpenter_trust" {
  # checkov:skip=CKV_TF_1:Module version constraints are acceptable (better than commit hashes for maintainability)
  count = var.hosted_control_plane && var.karpenter ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.karpenter_oidc_url}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.karpenter_oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.karpenter_oidc_url}:aud"
      values   = ["openshift"]
    }
  }
}

data "aws_iam_policy_document" "karpenter_policy" {
  count = var.hosted_control_plane && var.karpenter ? 1 : 0

  statement {
    sid    = "KarpenterEC2"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "KarpenterPassRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    # allow karpenter to assign the worker role to nodes it provisions
    resources = [local.worker_role_arn]
  }

  statement {
    sid    = "KarpenterSQS"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "KarpenterPricing"
    effect    = "Allow"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "karpenter" {
  # checkov:skip=CKV_AWS_274:Karpenter requires broad EC2 permissions for dynamic node provisioning
  count = var.hosted_control_plane && var.karpenter ? 1 : 0

  name               = "${var.cluster_name}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_trust[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "karpenter" {
  count = var.hosted_control_plane && var.karpenter ? 1 : 0

  name   = "${var.cluster_name}-karpenter"
  role   = aws_iam_role.karpenter[0].id
  policy = data.aws_iam_policy_document.karpenter_policy[0].json
}
