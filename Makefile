# unero-platform-terraform — substrate operations
# Usage: make plan ENV=dev
ENV ?= dev
ENVDIR := environments/$(ENV)
.PHONY: fmt validate init plan apply destroy scan check

fmt:
	terraform fmt -recursive

validate:
	cd $(ENVDIR) && terraform validate

init:
	cd $(ENVDIR) && terraform init

plan:
	cd $(ENVDIR) && terraform plan -out=tfplan

apply:
	cd $(ENVDIR) && terraform apply tfplan

destroy:
	cd $(ENVDIR) && terraform destroy

scan:
	checkov -d . --config-file policies/checkov.yaml
	tfsec . --config-file policies/tfsec.yaml

# Same gate as CI (ADR-024 philosophy: local == CI)
check: fmt validate scan
