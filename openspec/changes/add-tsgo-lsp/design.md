## Context

KoalaVim currently uses vtsls (a wrapper around VS Code's TypeScript language service) as its sole TypeScript/JavaScript LSP server. The server is registered in the global `LSP_SERVERS` table, installed via Mason, and accompanied by the `nvim-vtsls` plugin for extra commands. Configuration lives in `.kvim.conf` under `lsp.vtsls`.

Microsoft's tsgo — a Go rewrite of the TypeScript compiler — now ships a native LSP server. It's already in Mason's registry (`@typescript/native-preview`), in mason-lspconfig's filetype mappings, and in nvim-lspconfig (`lsp/tsgo.lua`). It accepts the same `settings.typescript.inlayHints.*` shape as vtsls.

## Goals / Non-Goals

**Goals:**
- Allow users to opt in to tsgo as their TypeScript LSP via a config flag
- Maintain full backwards compatibility — vtsls remains the default
- Reuse the existing inlay hints settings for both servers
- Provide health-check feedback when tsgo is configured but unavailable

**Non-Goals:**
- Running vtsls and tsgo simultaneously (dual-server mode)
- Auto-detecting tsgo and switching without explicit opt-in
- Adding tsgo-specific configuration knobs beyond `enabled` (can be added later)
- Feature-parity validation between tsgo and vtsls

## Decisions

### Decision: Config flag at `lsp.tsgo.enabled`

Add `lsp.tsgo` as a sibling to `lsp.vtsls` in the config, with a single `enabled` boolean (default `false`). This keeps the flat config pattern already used in `.kvim.conf`.

**Alternatives considered:**
- `lsp.typescript.server: "vtsls" | "tsgo"` — more extensible but introduces nesting inconsistent with the existing `lsp.vtsls` shape
- Auto-detect via `$PATH` — violates the "explicit opt-in" goal for an early-adopter feature

### Decision: Deferred server registration via LSP_LAZY_SERVERS

Since conf isn't available at module load time (lazy scans specs before conf is loaded), `typescript.lua` registers a resolver function in the `LSP_LAZY_SERVERS` global table instead of eagerly writing to `LSP_SERVERS`. The resolver runs in `general.lua`'s config function (where conf is available) and returns the server name + opts. This keeps all TypeScript-specific logic in `typescript.lua` — including the tsgo/vtsls decision, inlay hints, max_memory config, and health check. `general.lua` just iterates `LSP_LAZY_SERVERS` generically.

### Decision: nvim-vtsls always loaded

Lazy evaluates both `enabled` and `cond` during spec resolution, before `conf.load()` runs (the KoalaVim meta-plugin's `config` function). This means neither can read `.kvim.conf` values. nvim-vtsls is always loaded — its commands target vtsls specifically and are harmless no-ops when tsgo is the active server.

### Decision: No tsgo-specific settings initially

tsgo is a Go binary — `maxTsServerMemory` doesn't apply. No tsgo-specific config knobs beyond `enabled` for now. The `lsp.vtsls.max_memory` path continues to apply only when vtsls is active.

### Decision: Health check in the resolver

The tsgo resolver in `typescript.lua` checks `vim.fn.executable('tsgo')` and warns via `KoalaVim.health` if tsgo is enabled but not installed. This runs at config time alongside the server registration, keeping all tsgo logic co-located.

## Risks / Trade-offs

- **[Missing features]** tsgo doesn't yet support all vtsls features (some refactorings, project references). → Mitigation: this is an opt-in early-adopter feature; default remains vtsls. Users can switch back by setting `enabled: false`.
- **[nvim-vtsls commands unavailable]** Commands like "organize imports" and "add missing imports" from nvim-vtsls won't work with tsgo. → Mitigation: tsgo may implement equivalent code actions natively; users who need these commands stay on vtsls.
- **[Inlay hint label navigation]** tsgo doesn't yet compute inlay hint label locations (clicking hint parts to navigate to type definitions). → Mitigation: cosmetic limitation; hints still render correctly.
