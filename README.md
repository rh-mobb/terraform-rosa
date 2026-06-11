# Summary

This repository can be used as a module to create a ROSA cluster with the following components:

- ROSA networking in either private/public architecture
- ROSA cluster in either [Classic](https://docs.openshift.com/rosa/architecture/rosa-architecture-models.html#rosa-classic-architecture_rosa-architecture-models)
or [Hosted Control Plane](https://docs.openshift.com/rosa/architecture/rosa-architecture-models.html#rosa-hcp-architecture_rosa-architecture-models) architecture
- [Default machine pool](https://docs.openshift.com/rosa/rosa_cluster_admin/rosa_nodes/rosa-nodes-machinepools-about.html) with desired replica count
- Local HTPasswd [identity provider](https://docs.openshift.com/rosa/authentication/sd-configuring-identity-providers.html) with an "admin" user with Cluster Admin privileges
- Local HTPasswd [identity provider](https://docs.openshift.com/rosa/authentication/sd-configuring-identity-providers.html) with an "developer" user with basic privileges
- Optional GitOps operator deployment (OpenShift GitOps) after cluster creation
- Optional [Red Hat build of Karpenter (AutoNode)](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cluster_administration/rosa-hcp-autonode) for workload-aware, right-sized node provisioning (ROSA HCP only)


# Usage

The following Terraform is an example file to deploy a public ROSA cluster via this module.  This file
can be created wherever you would like to run Terraform from as a `main.tf` file.  A complete list of variables
and modifications is available via the [01-variables.tf](01-variables.tf) file:

**NOTE:** this is an overly simplistic file to demonstrate a simple installation.  You will need to tailor your
automation to your needs.  If there is functionality that is missing that you would like to see, please open an issue!

```
variable "token" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "developer_password" {
  type      = string
  sensitive = true
}

module "rosa_public" {
  source = "git::https://github.com/rh-mobb/terraform-rosa.git?ref=main"

  hosted_control_plane = false
  private              = false
  multi_az             = false
  replicas             = 2
  max_replicas         = 4
  cluster_name         = "my-rosa-cluster"
  ocp_version          = "4.15.14"
  token                = var.token
  admin_password       = var.admin_password
  developer_password   = var.developer_password
  pod_cidr             = "10.128.0.0/14"
  service_cidr         = "172.30.0.0/16"
  compute_machine_type = "m5.xlarge"

  tags = {
    "owner" = "me"
  }
}
```

Once the above has been created, normal Terraform commands can be run:

```bash
terraform init
terraform plan -out=rosa.plan
terraform apply rosa.plan
```

## Karpenter (AutoNode)

[Red Hat build of Karpenter](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cluster_administration/rosa-hcp-autonode) replaces static machine pools with dynamic, workload-aware node provisioning. Instead of pre-defining instance types and scaling thresholds, Karpenter evaluates the actual CPU, memory, and scheduling constraints of pending pods and provisions the optimal EC2 instance just-in-time — then continuously consolidates underutilized nodes.

**Requirements:**
- ROSA HCP cluster (`hosted_control_plane = true`)
- OpenShift 4.22 or later
- Karpenter runs in the hosted control plane — no pods are added to your worker nodes

**How to enable:**

Set `karpenter = true` in your module configuration or `terraform.tfvars`:

```hcl
module "rosa_hcp_karpenter" {
  source = "git::https://github.com/rh-mobb/terraform-rosa.git?ref=main"

  hosted_control_plane = true
  karpenter            = true
  cluster_name         = "my-karpenter-cluster"
  ocp_version          = "4.22.0"
  replicas             = 3        # must be a multiple of 3 for multi_az
  multi_az             = true
  token                = var.token
  admin_password       = var.admin_password
  developer_password   = var.developer_password
}
```

Or via environment variable:

```bash
export TF_VAR_karpenter=true
```

**What Terraform creates when `karpenter = true`:**

| Resource | Name | Purpose |
|---|---|---|
| `aws_iam_role` | `<cluster_name>-karpenter` | Karpenter controller role, trusted via OIDC |
| `aws_iam_role_policy` | `<cluster_name>-karpenter` | EC2, SQS, pricing, and PassRole permissions |

The cluster's `auto_node` attribute is set automatically — no additional configuration is required after `terraform apply`.

**Output:**

```bash
terraform output karpenter_role_arn
# arn:aws:iam::<account>:role/<cluster_name>-karpenter
```

**Default NodePool and EC2NodeClass — automatically applied:**

For public clusters, Terraform automatically applies a default `EC2NodeClass` and `NodePool` to the cluster after it is ready (via `22-karpenter-config.tf`, following the same pattern used for GitOps). No manual steps are required.

The defaults configure Karpenter to:
- Use the ROSA-managed AMI (`custom@latest`)
- Target the private subnets and security groups created by this module
- Accept x86 and Graviton (Arm) instances from the `c`, `m`, and `r` families, generation 6+
- Use Spot and On-Demand capacity
- Consolidate underutilized nodes after 30 seconds
- Cap total provisioned capacity at 1000 CPU cores

**For private clusters**, Terraform cannot reach the cluster API to apply manifests. Apply the following manually after cluster creation:

```yaml
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiSelectorTerms:
    - alias: custom@latest
  subnetSelectorTerms:
    - tags:
        kubernetes.io/cluster/<cluster_name>: shared
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/<cluster_name>: owned
  role: <cluster_name>-HCP-ROSA-Worker-Role
---
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
```

**Note:** Karpenter coexists with Cluster Autoscaler and manually managed machine pools. Use node selectors or taints/tolerations to direct specific workloads to Karpenter-managed nodes.

**Before committing code**, run the pre-commit checks:

```bash
make pr
```

This will validate your Terraform configuration, check formatting, and run linting tools. For a full test suite including terraform plan (requires credentials), use:

```bash
make test
```

Optional linting tools (recommended):
- **tflint**: Terraform linter for best practices (`brew install tflint`)
- **checkov**: Security scanning (`pip install checkov==3.2.495`)

**Note:** For consistent results, use checkov version 3.2.495 (same as CI). Different versions may report different checks.

These tools are optional - both `make pr` and `make test` will use them if installed, but won't fail if they're missing.

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0.0
- RHCS Provider >= 1.7.1

## File Organization

This repository uses a numbered prefix system for Terraform files to ensure they are processed in a logical order and to make the codebase structure clear:

### File Numbering Scheme

- **00-19: Cluster Infrastructure Setup**
  - `00-provider.tf` - Provider configuration and Terraform settings
  - `01-variables.tf` - Variable definitions
  - `02-network.tf` - Network module and VPC configuration
  - `03-roles.tf` - IAM roles and OIDC provider setup
  - `04-cluster.tf` - ROSA cluster resources (Classic and HCP)
  - `05-identity.tf` - Identity providers (HTPasswd)
  - `07-bastion.tf` - Bastion host (optional, for private clusters)

- **20: Cluster Access**
  - `20-cluster-login.tf` - Cluster login and readiness verification

- **21-29: Workload Installation**
  - `21-gitops.tf` - GitOps operator deployment (optional)
  - `22-karpenter-config.tf` - Karpenter EC2NodeClass and NodePool (optional, public clusters only)

- **90-99: Final Steps**
  - `99-outputs.tf` - Output values

This numbering scheme ensures:
1. Infrastructure is created before workloads are deployed
2. Cluster access is established before installing components
3. Outputs are always processed last
4. Room for future additions in each category

## Makefile Targets

This repository includes a Makefile with convenient targets:

- `make init` - Initialize Terraform and upgrade providers
- `make plan` - Create a Terraform plan (requires environment variables)
- `make apply` - Apply the plan
- `make cluster` or `make cluster-public` - Deploy a public ROSA cluster
- `make cluster-private` - Deploy a private ROSA cluster
- `make classic` - Deploy a ROSA Classic cluster
- `make hcp` - Deploy a ROSA HCP cluster
- `make destroy` - Destroy the infrastructure
- `make login` - Login to the cluster using oc CLI

To deploy a cluster with the GitOps operator:
```bash
TF_VAR_deploy_gitops=true make cluster
```

Required environment variables:
- `TF_VAR_admin_password` - Password for the admin user
- `TF_VAR_cluster_name` - Name of the cluster
- `TF_VAR_token` - OCM offline token for authentication (from [console.redhat.com/openshift/token](https://console.redhat.com/openshift/token))

Alternatively, authenticate using a service account with client credentials instead of an offline token:
- `TF_VAR_client_id` - OCM service account client ID
- `TF_VAR_client_secret` - OCM service account client secret

Optional environment variables:
- `TF_VAR_karpenter=true` - Enable Karpenter (AutoNode) for ROSA HCP clusters

## Versioning

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The current version is stored in the `VERSION` file, and all changes are documented in `CHANGELOG.md`.

### Cutting a New Release

To create a new version:

1. **Update CHANGELOG.md**:
   - Move items from `[Unreleased]` to a new version section (e.g., `## [1.1.0] - 2024-12-20`)
   - Categorize changes appropriately (Added, Changed, Fixed, etc.)
   - Update version comparison links at the bottom

2. **Update VERSION file**:
   - Set the new version number (e.g., `1.1.0`)

3. **Commit and tag**:
   ```bash
   git add VERSION CHANGELOG.md
   git commit -m "chore: release v$(cat VERSION)"
   git tag -a "v$(cat VERSION)" -m "Release v$(cat VERSION)"
   git push origin main --tags
   ```

4. **Create GitHub Release** (optional):
   - Use the tag created above
   - Copy the relevant changelog entry as release notes

See [CHANGELOG.md](CHANGELOG.md) for the full change history.
