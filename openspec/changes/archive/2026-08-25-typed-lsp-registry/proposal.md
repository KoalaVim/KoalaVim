## Why

LSP server registration used two separate global tables (`LSP_SERVERS` for static opts, `LSP_LAZY_SERVERS` for resolver functions) with no type safety. Resolver functions had to manually fetch config via `require('KoalaVim').conf.lsp`, and the config table was untyped — no LuaLS autocomplete or checking. The JSON config schema (`config_scheme.jsonc`) was the source of truth for config shape but Lua code couldn't benefit from it.

## What Changes

- Collapse `LSP_SERVERS` and `LSP_LAZY_SERVERS` into a single polymorphic `LSP_SERVERS` table that accepts both static opts (keyed by server name) and resolver functions (appended via helper)
- Add `LSP_SERVER(resolver)` helper function with `LspServerResolver` type alias so resolvers receive typed `KoalaVim.Conf.lsp` config
- Add codegen script (`scripts/gen_conf_types.lua`) that reads `config_scheme.jsonc` and generates LuaLS `---@class` annotations into `lua/KoalaVim/types/conf.lua`
- Remove the `LAZY_LSP_SERVERS` global entirely

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `lsp`: Server registration requirement now supports resolver functions that receive typed config, not just static opts tables
- `core-framework`: Global registries requirement updated for unified `LSP_SERVERS` table; configuration schema validation now includes LuaLS type generation from the JSON schema

## Impact

- `lua/KoalaVim/plugins/globals.lua`: Removed `LAZY_LSP_SERVERS`, added `LSP_SERVER()` helper and `LspServerResolver` alias
- `lua/KoalaVim/plugins/lsp/general.lua`: Consumer resolves both table and function entries from single `LSP_SERVERS`
- `lua/KoalaVim/plugins/lsp/servers/typescript.lua`: Uses `LSP_SERVER()` helper
- `lua/KoalaVim/types/conf.lua`: New generated file (LuaLS `---@meta`)
- `scripts/gen_conf_types.lua`: New codegen script
- `Makefile`: New `gen-types` target
