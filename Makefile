REQUIRED_ENVS = AAA TF_VAR_admin_password TF_VAR_cluster_name TF_VAR_token

init:
	@terraform init --upgrade

plan: check-env
	@terraform plan -out main.plan

cluster-private: check-env init plan
	@export TF_VAR_private=true && terraform apply main.plan

cluster-public: check-env init
	@export TF_VAR_private=false
	@terraform plan -out main.plan
	terraform apply main.plan

cluster: cluster-public

destroy:
	terraform destroy

login:
	@oc login $(shell terraform output -raw cluster_api_url) \
        --username admin --password $(TF_VAR_admin_password)

classic: check-env init
	@export TF_VAR_hosted_control_plane=false
	terraform plan -out main.plan
	terraform apply main.plan

check-env:
	@test -n "$(TF_VAR_admin_password)" || (echo "Please set TF_VAR_admin_password" && exit 1)
	@test -n "$(TF_VAR_cluster_name)" || (echo "Please set TF_VAR_cluster_name" && exit 1)
	@test -n "$(TF_VAR_token)" || (echo "Please set TF_VAR_token" && exit 1)
