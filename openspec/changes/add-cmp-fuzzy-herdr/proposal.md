## Why

Words in neighboring Herdr terminals, including output that has scrolled off screen, are useful completion candidates but are unavailable to buffer completion. A dedicated fuzzy source makes that context available while editing in Neovim.

## What Changes

- Create a standalone `KoalaVim/cmp-fuzzy-herdr` plugin registering the `fuzzy_herdr` nvim-cmp source and using `KoalaVim/fuzzy.nvim`.
- Default to other panes in the current Neovim pane's Herdr tab, reading bounded recent output including scrollback.
- Support plugin-wide configuration and per-source overrides for pane scope, capture mode and limits, caching, and fuzzy matching.
- Fetch asynchronously, deduplicate candidates, handle unavailable panes gracefully, and avoid stale results across tab changes.
- Load the plugin with `cmp-fuzzy-buffer` and add it wherever KoalaVim enables the buffer source, ranking below buffer completion where priorities are specified.

## Capabilities

### New Capabilities

- `herdr-completion`: Standalone fuzzy completion from configurable Herdr pane content with asynchronous bounded capture and layered configuration.

### Modified Capabilities

- `autocompletion`: Enable Herdr completion alongside fuzzy buffer completion in KoalaVim.

## Impact

- New repository under the KoalaVim organization: `cmp-fuzzy-herdr`, with source code, documentation, and focused tests during implementation.
- KoalaVim integration in `lua/KoalaVim/plugins/autocomplete.lua`, including normal insert completion and buffer-source configurations for search, debug watches, and Cargo.toml.
- Dependencies: nvim-cmp, KoalaVim/fuzzy.nvim, and a compatible Herdr executable/runtime for capture. Outside Herdr the source is inactive.
- No changes to Herdr itself or to existing command confirmation behavior.
