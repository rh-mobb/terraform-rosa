init:
	@terraform init

plan:
	@export TF_VAR_token="$$(bw get password ocm-api-key)" && terraform plan -out main.plan -var-file=main.tfvars

cluster-private:
	@export TF_VAR_private=true && terraform apply main.plan

cluster-public:
	@export TF_VAR_private=false && terraform apply main.plan

destroy:
	@export TF_VAR_token="$$(bw get password ocm-api-key)" && terraform apply -destroy -var-file=main.tfvars