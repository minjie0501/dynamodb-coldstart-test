test:
	npm run test

tf-output:
	terraform output -json | jq 'with_entries(.value |= .value)' > build/terraform-outputs.json

tf-plan:
	terraform plan --var-file "tf_vars/$(shell terraform workspace show).tfvars"

tf-apply:
	terraform apply --var-file "tf_vars/$(shell terraform workspace show).tfvars"
	make tf-output

sls-offline:
	sls offline start --reloadHandler

setup:
	npm install
	npm run prepare
	mkdir -p build && touch build/terraform-outputs.json && echo '{}' > build/terraform-outputs.json
	tfswitch
	terraform init
	terraform workspace select stag
	terraform output -json | jq 'with_entries(.value |= .value)' > build/terraform-outputs.json
