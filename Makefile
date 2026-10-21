dev-setup: ## Setup dev environment (git hooks)
	git config --local include.path ../.gitconfig

tmpconfig: ## Make a skeleton for a template config
	@./.internal/makescripts/tmpconfig

gen-types: ## Generate LuaLS type annotations from config_scheme.jsonc
	nvim -l scripts/gen_conf_types.lua

test-keymaps: ## Check the keymaps of both flavors (headless, needs kv + a KoalaVim env)
	@sh dev/test_keymaps.sh

gen-keymaps-doc: ## Generate the per-flavor keymap cheat sheet (docs/keymaps.md) from contested.lua
	nvim -l scripts/gen_keymaps_doc.lua

help: ## Prints help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
