.DEFAULT_GOAL := help
ENVIRONMENT ?= dev
COMPONENT ?= all

##@ Validation

.PHONY: fmt
fmt: ## Format all OpenTofu files
	tofu fmt -recursive components/
	tofu fmt -recursive modules/

.PHONY: fmt-check
fmt-check: ## Check formatting without modifying files
	tofu fmt -check -recursive components/
	tofu fmt -check -recursive modules/

.PHONY: validate
validate: ## Validate all components (init + validate)
	@for dir in components/*/; do \
		name=$$(basename $$dir); \
		echo "Validating $$name..."; \
		cd $$dir && tofu init -backend=false -input=false > /dev/null 2>&1 && tofu validate && cd - > /dev/null || exit 1; \
	done
	@echo "All components valid."

.PHONY: lint
lint: ## Run tflint on all components
	tflint --recursive --config .tflint.hcl

##@ Planning

.PHONY: plan
plan: ## Plan for ENVIRONMENT (default: dev). Use COMPONENT=network|cluster|druid|all
	@if [ "$(COMPONENT)" = "all" ]; then \
		cd live/$(ENVIRONMENT) && terragrunt run-all plan; \
	else \
		cd live/$(ENVIRONMENT)/$(COMPONENT) && terragrunt plan; \
	fi

.PHONY: apply
apply: ## Apply for ENVIRONMENT. Use COMPONENT=network|cluster|druid|all
	@if [ "$(COMPONENT)" = "all" ]; then \
		cd live/$(ENVIRONMENT) && terragrunt run-all apply; \
	else \
		cd live/$(ENVIRONMENT)/$(COMPONENT) && terragrunt apply; \
	fi

##@ Backend

.PHONY: init-backend
init-backend: ## Create S3 backend bucket for state
	./scripts/init-backend.sh

##@ Help

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m [ENVIRONMENT=dev|staging|production] [COMPONENT=network|cluster|druid|all]\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
