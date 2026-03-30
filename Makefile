.PHONY: help fmt validate lint docs plan-dev plan-prod init-dev init-prod test clean

SHELL := /bin/bash

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all Terraform files
	terraform fmt -recursive .

validate: ## Validate Terraform configuration for all environments
	@for env in dev prod; do \
		echo "==> Validating $$env..."; \
		cd environments/$$env && terraform validate && cd ../..; \
	done

lint: ## Run TFLint on all environments
	@for env in dev prod; do \
		echo "==> Linting $$env..."; \
		cd environments/$$env && tflint --config=../../.tflint.hcl && cd ../..; \
	done

docs: ## Generate module documentation with terraform-docs
	terraform-docs markdown table modules/vnet --output-file README.md --output-mode inject

init-dev: ## Initialize dev environment
	cd environments/dev && terraform init

init-prod: ## Initialize prod environment
	cd environments/prod && terraform init

plan-dev: ## Plan dev environment
	cd environments/dev && terraform plan -out=dev.tfplan

plan-prod: ## Plan prod environment
	cd environments/prod && terraform plan -out=prod.tfplan

apply-dev: ## Apply dev environment (requires plan)
	cd environments/dev && terraform apply dev.tfplan

apply-prod: ## Apply prod environment (requires plan)
	cd environments/prod && terraform apply prod.tfplan

test: test-static test-module ## Run all tests

test-static: ## Run static validation tests (no cloud credentials needed)
	bash tests/static/validate.sh

test-module: ## Run Terratest module tests (requires Azure credentials)
	cd modules/vnet/tests && go test -v -timeout 30m

test-integration: ## Run plan-level integration tests (requires Azure credentials)
	cd environments/dev && terraform plan -out=test.tfplan && terraform show -json test.tfplan > /tmp/dev-plan.json && rm test.tfplan
	cd environments/prod && terraform plan -out=test.tfplan && terraform show -json test.tfplan > /tmp/prod-plan.json && rm test.tfplan
	cd tests/integration && DEV_PLAN_JSON=/tmp/dev-plan.json PROD_PLAN_JSON=/tmp/prod-plan.json go test -v -timeout 10m

test-policy: ## Run OPA policy tests (requires conftest + Azure credentials)
	bash tests/policy/conftest.sh dev
	bash tests/policy/conftest.sh prod

clean: ## Remove Terraform cache and plan files
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
