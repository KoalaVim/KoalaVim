dev-setup: ## Setup dev environment (git hooks)
	git config --local include.path ../.gitconfig

tmpconfig: ## Make a skeleton for a template config
	@./.internal/makescripts/tmpconfig

gen-types: ## Generate LuaLS type annotations from config_scheme.jsonc
	nvim -l scripts/gen_conf_types.lua

help: ## Prints help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
