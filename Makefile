.PHONY: init
init: init_tf init_pre_commit_reqs

init_tf: ## Ensure terraform and terragrunt is installed and activated correctly using .version files
	brew install -q tgenv tgenv sops
	tgenv install
	tfenv install
	tgenv list
	tfenv list

init_pre_commit_reqs: ## Ensure pre-commit repo packages dependencies are available.
	brew install -q commitizen pre-commit terraform-docs tflint tfsec checkov terrascan infracost tfupdate minamijoyo/hcledit/hcledit jq yq
	npm install

.PHONY: ensure_pre_commit
ensure_pre_commit:  ## Ensure pre-commit is installed
	pre-commit install
	pre-commit install-hooks

.PHONY: pre_commit_tests
pre_commit_tests: ensure_pre_commit ## Run pre-commit tests
	pre-commit run --a

.PHONY: clean_pre_commit ## Clean pre-commit - Useful for troubleshooting dirty plugins
clean_pre_commit:
	pre-commit clean
	pre-commit gc

.PHONY: test ## Perform pre-commit tests
test: pre_commit_tests
