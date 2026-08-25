## Context

LSP server registration previously used two globals: `LSP_SERVERS` (string-keyed, static opts) and `LSP_LAZY_SERVERS` (array of resolver closures). Only TypeScript used the lazy pattern — its resolver reads runtime config to choose between `tsgo` and `vtsls`. Both tables were consumed in the same `config` phase of `nvim-lspconfig`, making the "lazy" distinction misleading. Config values inside resolvers were untyped (`table`), and the JSON schema that defines config shape had no connection to Lua's type system.

## Goals / Non-Goals

**Goals:**
- Single `LSP_SERVERS` table for all server registrations (static and dynamic)
- Typed resolver callback via `LSP_SERVER()` helper so LuaLS infers `conf` fields
- Config types generated from `config_scheme.jsonc` — single source of truth
- No breaking change to existing `LSP_SERVERS['name'] = opts` pattern

**Non-Goals:**
- Typing the full `require('KoalaVim').conf` object across all consumers (only LSP resolvers for now)
- Removing globals in favor of a module system (tracked by existing TODO in globals.lua)
- Auto-running codegen (manual `make gen-types` is sufficient)

## Decisions

### Single polymorphic table over two separate tables

The consumer in `general.lua` iterates `LSP_SERVERS` with `pairs()` and checks `type(value)` — functions get called with `lsp_conf`, tables pass through as-is. The resolved map is written back to `LSP_SERVERS` so downstream runtime code (`utils/lsp.lua`) continues to work unchanged.

Alternative: keep two tables but rename. Rejected because the split had no semantic value — both are consumed at the same time.

### Helper function over raw `table.insert`

`LSP_SERVER(resolver)` is annotated `---@param resolver LspServerResolver` which lets LuaLS propagate the `KoalaVim.Conf.lsp` type into the callback parameter. Raw `table.insert` loses this inference. The helper also encapsulates the registration mechanism.

### Codegen from JSON schema over hand-written Lua classes

A Lua script (`scripts/gen_conf_types.lua`) parses `config_scheme.jsonc`, strips JSONC comments, walks the schema tree, and emits `---@class` annotations into a `---@meta` file. This avoids duplicating the config shape and drifting over time.

Alternative: hand-written `---@class` in globals.lua. Rejected because it duplicates the schema and will inevitably drift.

Alternative: LuaCATS plugin that reads JSON schema natively. No such plugin exists.

## Risks / Trade-offs

- **Generated file must be re-run manually** → Acceptable for now; `make gen-types` is documented. Could add a pre-commit hook later.
- **`---@meta` file must be in LuaLS's workspace** → `lua/KoalaVim/types/` is inside the Lua path, so LuaLS picks it up automatically.
- **Modifying `LSP_SERVERS` global mid-resolution** → The consumer builds a fresh `servers` local and assigns it back, so no mutation during iteration.
