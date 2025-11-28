# Terraform ROSA Project Rules

## Project Overview
This is a Terraform module for deploying Red Hat OpenShift Service on AWS (ROSA) clusters, supporting both Classic and Hosted Control Plane (HCP) architectures.

## File Organization and Numbering Scheme

### File Numbering Convention
All Terraform files use numeric prefixes to ensure proper execution order and logical grouping:

- **00-19: Cluster Infrastructure Setup**
  - `00-provider.tf` - Provider configuration and Terraform settings
  - `01-variables.tf` - Variable definitions
  - `02-network.tf` - Network module and VPC configuration
  - `03-roles.tf` - IAM roles and OIDC provider setup
  - `04-cluster.tf` - ROSA cluster resources (Classic and HCP)
  - `05-identity.tf` - Identity providers (HTPasswd)
  - `06-bastion.tf` - Bastion host (optional, for private clusters)

- **20: Cluster Access**
  - `20-cluster-login.tf` - Cluster login and readiness verification (multiple resources for progress tracking)

- **21-29: Workload Installation**
  - `21-gitops.tf` - GitOps operator deployment (optional)

- **90-99: Final Steps**
  - `99-outputs.tf` - Output values (always processed last)

### Rules for Adding New Files
- Use the appropriate number range based on the resource type
- Leave gaps in numbering (e.g., 07, 08, 09) for future additions
- Always use `99-outputs.tf` for outputs (never use 90-98)
- When adding new files, maintain logical grouping within ranges

## Makefile Usage

### Available Targets
- `make` or `make help` - Show help message with all available targets
- `make init` - Initialize Terraform and upgrade providers
- `make plan` - Create a Terraform plan (requires environment variables)
- `make apply` - Apply the Terraform plan
- `make cluster` or `make cluster-public` - Deploy a public ROSA cluster
- `make cluster-private` - Deploy a private ROSA cluster
- `make classic` - Deploy a ROSA Classic cluster (explicit)
- `make hcp` - Deploy a ROSA Hosted Control Plane (HCP) cluster
- `make destroy` - Destroy the infrastructure (auto-approve)
- `make login` - Login to the cluster using oc CLI

### Required Environment Variables
- `TF_VAR_admin_password` - Password for the admin user (14+ chars, uppercase + symbol/number)
- `TF_VAR_cluster_name` - Name of the ROSA cluster
- `TF_VAR_token` - OCM token for authentication

### Optional Environment Variables
- `TF_VAR_developer_password` - Password for the developer user
- `TF_VAR_ocp_version` - OpenShift version (e.g., 4.20.18). If not set, uses latest stable
- `TF_VAR_region` - AWS region (default: us-east-1)
- `TF_VAR_private` - Set to 'true' for private cluster (default: false)
- `TF_VAR_hosted_control_plane` - Set to 'true' for HCP cluster (default: true, can override)
- `TF_VAR_multi_az` - Set to 'true' for multi-AZ deployment (default: false)
- `TF_VAR_deploy_gitops` - Set to 'true' to deploy GitOps operator (default: false)

### Examples
```bash
# Deploy public cluster with GitOps
TF_VAR_deploy_gitops=true make cluster

# Deploy private cluster
make cluster-private

# Deploy HCP cluster
make hcp
```

## Code Style and Conventions

### Terraform Code
- Use `terraform_data` resources with `local-exec` provisioners for cluster operations that require `oc` CLI
- Avoid using Kubernetes provider in the same module as cluster creation (use separate modules/workspaces)
- Use `check` blocks for validation instead of conditional resource creation when possible
- Use `locals` blocks for computed values and conditional logic
- Prefer `depends_on` for explicit resource dependencies

### Shell Scripts in Provisioners
- Use single `$` for shell variables (Terraform only interpolates `${...}`)
- Use `$$` to escape literal `$` when needed (e.g., `%%{http_code}` in curl)
- Always use `set -e` at the start of scripts for error handling
- Provide clear progress messages with elapsed time for long-running operations
- Use retry logic with exponential backoff for operations that may fail transiently

### Resource Naming
- Use descriptive names that indicate the resource type and purpose
- Follow Terraform naming conventions (lowercase with underscores)
- Use `count` or `for_each` appropriately for conditional resources

### Variable Definitions
- Always include `description` for all variables
- Use `sensitive = true` for passwords and tokens
- Use `nullable = true` with `default = null` for optional variables
- Provide meaningful default values when appropriate

### Validation
- Use `validation` blocks in variables for input validation
- Use `check` blocks for runtime validation
- Use `precondition` and `postcondition` in lifecycle blocks for resource-specific validation

## ROSA-Specific Guidelines

### Cluster Types
- Classic clusters: Use `rhcs_cluster_rosa_classic` resource
- HCP clusters: Use `rhcs_cluster_rosa_hcp` resource
- Default to HCP (`TF_VAR_hosted_control_plane=true` by default in Makefile)

### Private Clusters
- Private clusters cannot be accessed directly from local machine
- Cluster login and GitOps deployment are not supported for private clusters
- Use bastion host for private cluster access
- Validation blocks prevent invalid combinations (private + gitops)

### Identity Providers
- HTPasswd identity providers are created for admin and developer users
- Group membership resource (`rhcs_group_membership`) is deprecated - handle manually
- Admin user should be added to `cluster-admins` group manually after cluster creation

### Version Selection
- If `ocp_version` is not specified, automatically selects latest stable version
- Uses `rhcs_versions` data source to query available versions
- Separate version queries for Classic and HCP clusters

## Module Structure

### Networking Module
- Located in `modules/terraform-rosa-networking/`
- Handles VPC, subnets, NAT gateways, internet gateways, and route tables
- Supports both single-AZ and multi-AZ configurations
- Supports private/public networking

### Dependencies
- Cluster resources depend on network and IAM roles
- Identity providers depend on cluster
- Cluster login depends on cluster and identity provider
- GitOps deployment depends on cluster login and nodes being ready

## Testing and Validation

### Before Committing
- Run `make pr` to run all pre-commit checks (validate, fmt -check, plan)
- This single command will:
  - Validate Terraform syntax (`terraform validate`)
  - Check code formatting (`terraform fmt -check -recursive`)
  - Run tflint (if installed) - checks for best practices and common errors
  - Run checkov security scan (if installed) - checks for security issues
  - Verify a plan can be created (`terraform plan`)
- **Optional linting tools** (recommended but not required):
  - `tflint` - Terraform linter (install: `brew install tflint` or download from [tflint.dev](https://tflint.dev))
  - `checkov` - Security scanning (install: `pip install checkov`)
  - These tools are optional - `make pr` will run them if available, but won't fail if missing
- Alternatively, run individual checks:
  - `terraform validate` to check syntax
  - `terraform fmt -check` to ensure formatting
  - `tflint` to run linting (if installed)
  - `checkov -d . --framework terraform` for security scanning (if installed)
  - `make plan` to test the configuration
- Verify Makefile targets work correctly

### Common Issues
- DNS resolution may take time after cluster creation - wait for DNS before login
- Identity provider may need time to be ready - use retry logic for login
- Private clusters cannot use cluster login or GitOps deployment
- Ensure all shell variables use single `$` (not `$$`) unless escaping is needed

## Additional Terraform Best Practices

### Output Definitions
- Always include `description` for all outputs
- Use `sensitive = true` for outputs containing sensitive data
- Consider using `depends_on` in outputs if they depend on resources that might not be obvious

### State Management
- Use remote state backends (S3, Terraform Cloud, etc.) for production environments
- Configure state locking to prevent concurrent modifications
- Never commit state files to version control (already in `.gitignore`)
- Use `.terraformignore` to exclude unnecessary files from Terraform operations
- Consider using workspaces for environment separation (dev, staging, prod)

### Code Comments
- Add comments for complex logic or non-obvious decisions
- Document why certain workarounds or patterns are used
- Explain any provider-specific quirks or limitations
- Comment on resource lifecycle decisions (create_before_destroy, prevent_destroy, etc.)

### Data Sources
- Organize data sources logically (e.g., in a `data.tf` file if many exist)
- Use data sources to avoid hardcoding values (region, account ID, AMI IDs, etc.)
- Cache data source results when appropriate to avoid unnecessary API calls

### Module Usage
- When using this as a module, pin to specific versions or tags (not `main` branch)
- Document module version compatibility in README
- Use semantic versioning for module releases

### Resource Lifecycle
- Use `lifecycle` blocks for resources that need special handling:
  - `create_before_destroy` for resources that can't be replaced in-place
  - `prevent_destroy` for critical resources (use sparingly)
  - `ignore_changes` for attributes managed outside Terraform (document why)
- Document lifecycle decisions in comments

### Error Handling
- Provide clear, actionable error messages in validation blocks
- Use `precondition` and `postcondition` for resource-specific validation
- Include context in error messages (what failed, why, how to fix)

### CI/CD Considerations
- Run `make pr` in CI/CD pipelines before merging
- Use remote state backends in CI/CD environments
- Configure appropriate state locking timeouts
- Use service accounts/roles with minimal required permissions
- Store sensitive variables in CI/CD secret management (not in code)

### Performance
- Use `for_each` instead of `count` when possible (more stable resource addressing)
- Avoid unnecessary `depends_on` (Terraform usually infers dependencies)
- Use `-target` sparingly and only for debugging
- Consider using `terraform plan -refresh=false` for faster plans when state is current

### Security
- Never commit secrets, tokens, or passwords
- Use environment variables or secret management systems
- Mark sensitive variables and outputs appropriately
- Review IAM policies for least privilege
- Regularly update provider versions for security patches

## Versioning and Releases

### Version Numbering
- Follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (MAJOR.MINOR.PATCH)
- Version is stored in `VERSION` file
- Update `CHANGELOG.md` for all releases

### Cutting a New Version

1. **Update CHANGELOG.md**:
   - Move items from `[Unreleased]` to a new version section
   - Use format: `## [X.Y.Z] - YYYY-MM-DD`
   - Categorize changes: Added, Changed, Deprecated, Removed, Fixed, Security
   - Update the version links at the bottom of the file

2. **Update VERSION file**:
   - Update the version number to match the new release (e.g., `1.0.0`)

3. **Create git tag**:
   ```bash
   git add VERSION CHANGELOG.md
   git commit -m "chore: release v$(cat VERSION)"
   git tag -a "v$(cat VERSION)" -m "Release v$(cat VERSION)"
   git push origin main --tags
   ```

4. **Create GitHub Release** (if applicable):
   - Use the tag created above
   - Copy the changelog entry for this version as the release notes

### Version Bump Guidelines
- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.X.0): New features, backwards compatible
- **PATCH** (0.0.X): Bug fixes, backwards compatible

## Documentation
- Keep README.md updated with usage examples
- Document all variables in `01-variables.tf`
- Add comments for complex logic or non-obvious decisions
- Update file numbering documentation when adding new files
- Update CHANGELOG.md for all user-facing changes
