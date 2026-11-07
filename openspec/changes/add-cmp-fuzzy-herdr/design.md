## Context

See proposal.md for motivation. KoalaVim uses nvim-cmp and KoalaVim fuzzy source forks. `autocomplete.lua` centralizes buffer source construction but also installs it in search, debug watches, and Cargo.toml configurations. The existing fuzzy-buffer comparator only compares its own source name.

The installed Herdr exposes pane enumeration, pane metadata with tab identity, and `pane read` with `visible` and `recent-unwrapped` sources plus a line limit. Exact JSON envelopes and history retention semantics must be verified against the supported runtime during implementation. A new standalone plugin and asynchronous capture justify this design artifact.

## Goals / Non-Goals

**Goals:** Keep transport, configuration, matching, and cmp integration independently testable; prevent stale captures from crossing source configurations or tab contexts; keep completion responsive.

**Non-Goals:** Changing Herdr, collecting unlimited terminal history, completing whole terminal transcripts, and changing colon command-line completion.

## Decisions

### Standalone source under KoalaVim

Create `KoalaVim/cmp-fuzzy-herdr` with `lua/cmp_fuzzy_herdr`, automatic source registration, a source-local score comparator, documentation, and focused headless tests. Depend on nvim-cmp and `KoalaVim/fuzzy.nvim`. Keep Herdr capture independent of KoalaVim utility modules so other Neovim configurations can use it. Extending fuzzy-buffer would couple terminal lifecycle to buffer enumeration and require synthetic buffers, so use a separate source.

### Configuration resolution

Expose optional `require('cmp_fuzzy_herdr').setup({...})` and accept the same settings in the nvim-cmp source `option` table. Resolve built-in defaults, plugin setup, then per-source options into a fresh configuration; replace explicit pane ID lists rather than merging list indices. Never mutate cmp parameters or other source configurations.

Proposed defaults:

| Option | Default | Behavior |
| --- | --- | --- |
| scope | `tab` | `tab`, `workspace`, or `panes` |
| pane_ids | empty list | Explicit targets for `panes` scope |
| exclude_current | `true` | Exclude HERDR_PANE_ID even in explicit scope |
| capture_source | `recent-unwrapped` | Also supports `visible` |
| max_lines | `2000` | Recent lines per pane, including retained scrollback |
| cache_ttl_ms | `500` | Reuse matching capture context briefly |
| timeout_ms | `1000` | Bound transport requests |
| fuzzy_backend | `fzy` | Use the shared fuzzy backend API |
| min_match_length | `1` | Minimum query/candidate length |
| max_match_length | `100` | Maximum candidate length |
| max_matches | `15` | Maximum returned candidates |

KoalaVim can set max_item_count independently through normal cmp source settings. Document both global setup and per-source examples, including visible-only and explicit-pane capture. History is bounded by both plugin limits and Herdr retention; it cannot recover discarded history.

### Resolve tab from the Neovim pane

Resolve HERDR_PANE_ID against current runtime metadata on each refresh. Select panes by that pane's tab identity, never by a globally focused tab that another client might change. Workspace scope uses the owning workspace; explicit scope uses the supplied IDs. Missing context fails closed. Hidden or zoom-obscured panes remain eligible because selection uses membership rather than visibility. Do not rely on an assumed HERDR_TAB_ID variable.

### Asynchronous CLI transport with isolated cache

Use argument-vector `vim.system` calls with text output, timeouts, and no shell interpolation. Prefer Herdr CLI metadata and plain-text reads instead of implementing a second socket client. Verify metadata response envelopes before coding selectors; use pane get/list or the runtime snapshot as needed to establish authoritative membership.

On a completion request, reuse a fresh compatible capture or asynchronously enumerate and read selected panes with bounded concurrency (four reads). Deduplicate concurrent captures sharing a key. Capture keys include socket/session identity, current pane, resolved tab/workspace, selected pane IDs, capture source, line limit, and transport settings; resolve matching options independently on each request. Drop obsolete completion generations and settle each callback exactly once. Recheck context before delivering asynchronous results. Expired or incompatible captures do not supply candidates; successful reads can survive an individual pane failure. Evict closed panes and bound the number of cached contexts.

Blocking shell reads on each keystroke would stall completion. A permanent polling process is unnecessary; short-lived request-driven caching keeps idle overhead low.

### Fuzzy words and ranking

Read plain text, remove residual terminal control sequences, extract word candidates with support for keyword characters and hyphens, deduplicate, then filter through the existing fuzzy backend API. Carry scores for the plugin comparator and use stable tie ordering. Set filterText for fuzzy acceptance by cmp, avoid reinserting the exact typed word in insert mode, and escape search delimiters in command-line mode. Do not change the existing buffer comparator or compare incompatible raw scores across sources.

### KoalaVim integration

Add the plugin as a dependency of the fuzzy-buffer spec so loading follows that plugin. Use a separate Herdr source helper beside the buffer source helper and include both entries in every existing buffer-source context; explicit entries avoid Lua multiple-return expansion pitfalls. Use priority 100 for Herdr versus buffer 150 and dictionary 50 in normal completion; preserve context-specific limits and buffer behavior. Install the Herdr comparator alongside the existing one. Preserve search, debug, and Cargo source grouping and leave colon completion unchanged.

## Risks / Trade-offs

- [Herdr JSON and scrollback behavior can vary] -> Confirm supported runtime behavior, document minimum compatibility, and test with realistic response fixtures and one live smoke check.
- [Large or rapidly changing terminal output] -> Bound lines, concurrency, cache contexts, and request duration; refresh after a short TTL.
- [Asynchronous tab moves or source overrides] -> Isolate cache keys and suppress obsolete request generations after context changes.
- [Source ranking can drift] -> Keep scores source-local and verify configured cmp priorities with the existing comparator chain.
- [New repository availability] -> Prepare the plugin repository before wiring its remote into a released KoalaVim configuration; use a local development checkout while verifying integration.

## Migration Plan

Prepare the standalone plugin, documentation, and tests first; verify locally through a lazy.nvim development override. Make the KoalaVim repository available before shipping the dependency and integration. No user setup is required for default behavior. Roll back by removing the Herdr dependency, paired source entries, and comparator; buffer completion remains intact.
