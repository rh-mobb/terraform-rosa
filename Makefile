.PHONY: help init plan apply destroy login check-env cluster cluster-public cluster-private classic hcp test pr

REQUIRED_ENVS = TF_VAR_admin_password TF_VAR_cluster_name TF_VAR_token

# Set default for hosted_control_plane (can be overridden via environment variable)
TF_VAR_hosted_control_plane ?= true
export TF_VAR_hosted_control_plane

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Terraform ROSA Cluster Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Required Environment Variables:"
	@echo "  TF_VAR_admin_password  - Password for the admin user (14+ chars, uppercase + symbol/number)"
	@echo "  TF_VAR_cluster_name     - Name of the ROSA cluster"
	@echo "  TF_VAR_token            - OCM token for authentication"
	@echo ""
	@echo "Optional Environment Variables:"
	@echo "  TF_VAR_developer_password - Password for the developer user"
	@echo "  TF_VAR_ocp_version        - OpenShift version (e.g., 4.20.18). If not set, uses latest stable"
	@echo "  TF_VAR_region             - AWS region (default: us-east-1)"
	@echo "  TF_VAR_private            - Set to 'true' for private cluster (default: false)"
	@echo "  TF_VAR_hosted_control_plane - Set to 'true' for HCP cluster (default: true, can override)"
	@echo "  TF_VAR_multi_az            - Set to 'true' for multi-AZ deployment (default: false)"
	@echo "  TF_VAR_deploy_gitops       - Set to 'true' to deploy GitOps operator (default: false)"
	@echo ""
	@echo "Examples:"
	@echo "  make cluster-public              # Deploy a public ROSA Classic cluster"
	@echo "  make cluster-private              # Deploy a private ROSA Classic cluster"
	@echo "  make classic                      # Deploy a ROSA Classic cluster (explicit)"
	@echo "  make hcp                          # Deploy a ROSA HCP cluster"
	@echo "  make plan                         # Create a Terraform plan"
	@echo "  make apply                        # Apply the plan"
	@echo "  make destroy                      # Destroy the infrastructure"
	@echo "  make login                        # Login to the cluster with oc CLI"
	@echo "  make test                         # Run full test suite (validate, fmt, lint, plan)"
	@echo "  make pr                           # Run pre-commit checks (validate, fmt, lint - skips plan)"
	@echo ""
	@echo "Deploy with GitOps operator:"
	@echo "  TF_VAR_deploy_gitops=true make cluster  # Deploy cluster with GitOps operator"

init: ## Initialize Terraform and upgrade providers
	@terraform init -upgrade

plan: check-env ## Create a Terraform plan (requires environment variables)
	@terraform plan -out=main.plan

apply: check-env ## Apply the Terraform plan
	@terraform apply main.plan

cluster-public: check-env init ## Deploy a public ROSA cluster
	@export TF_VAR_private=false && \
	terraform plan -out=main.plan && \
	terraform apply main.plan

cluster-private: check-env init ## Deploy a private ROSA cluster
	@export TF_VAR_private=true && \
	terraform plan -out=main.plan && \
	terraform apply main.plan

cluster: cluster-public ## Deploy a public ROSA cluster (alias for cluster-public)

classic: check-env init ## Deploy a ROSA cluster classic(explicit)
	@export TF_VAR_hosted_control_plane=false && \
	terraform plan -out=main.plan && \
	terraform apply main.plan

hcp: check-env init ## Deploy a ROSA Hosted Control Plane (HCP) cluster
	@export TF_VAR_hosted_control_plane=true && \
	terraform plan -out=main.plan && \
	terraform apply main.plan

destroy: ## Destroy the infrastructure
	@terraform destroy -auto-approve

login: ## Login to the cluster using oc CLI
	@oc login $(shell terraform output -raw cluster_api_url) \
		--username admin --password $(TF_VAR_admin_password)

check-env: ## Verify required environment variables are set
	@test -n "$(TF_VAR_admin_password)" || (echo "ERROR: Please set TF_VAR_admin_password" && exit 1)
	@test -n "$(TF_VAR_cluster_name)" || (echo "ERROR: Please set TF_VAR_cluster_name" && exit 1)
	@test -n "$(TF_VAR_token)" || (echo "ERROR: Please set TF_VAR_token" && exit 1)

test: check-env init ## Run full test suite (validate, fmt, lint, plan)
	@./test/test.sh

pr: init ## Run pre-commit checks (validate, fmt, lint - skips plan)
	@./test/pr.sh
