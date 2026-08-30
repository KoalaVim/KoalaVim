## 1. Unify LSP server registry

- [x] 1.1 Remove `LAZY_LSP_SERVERS` global from `globals.lua`
- [x] 1.2 Add `LspServerResolver` type alias and `LSP_SERVER()` helper to `globals.lua`
- [x] 1.3 Update `general.lua` consumer to resolve function entries from `LSP_SERVERS` and write resolved map back to global

## 2. Update server registrations

- [x] 2.1 Migrate `typescript.lua` from `table.insert(LAZY_LSP_SERVERS, ...)` to `LSP_SERVER(function(conf) ... end)`
- [x] 2.2 Remove manual `require('KoalaVim').conf.lsp` from typescript resolver — config now injected

## 3. Config type generation

- [x] 3.1 Create `scripts/gen_conf_types.lua` codegen script that reads `config_scheme.jsonc` and emits LuaLS `---@class` annotations
- [x] 3.2 Generate `lua/KoalaVim/types/conf.lua` (`---@meta` file) with full config type tree
- [x] 3.3 Wire `LspServerResolver` alias to use generated `KoalaVim.Conf.lsp` type
- [x] 3.4 Add `gen-types` target to `Makefile`
