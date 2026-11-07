## 1. Standalone plugin and configuration

- [x] 1.1 Prepare the standalone `KoalaVim/cmp-fuzzy-herdr` repository with source registration, dependency metadata, license, and headless test entry point; verify Neovim can load it as a local plugin and register `fuzzy_herdr`.
- [x] 1.2 Implement built-in defaults, optional global setup, and per-source configuration resolution; verify precedence, explicit-list replacement, and isolation between source instances with focused tests.

## 2. Herdr capture

- [x] 2.1 Verify supported Herdr metadata envelopes, tab/workspace ownership, plain-text reads, and retained recent-unwrapped history; capture representative fixtures and document runtime compatibility, confirming a word above the viewport is returned within the line limit.
- [x] 2.2 Implement tab, workspace, and explicit-pane selectors with current-pane exclusion and fail-closed context resolution; verify fixtures cover other tabs, zoom-hidden panes, moved panes, and missing metadata.
- [x] 2.3 Implement asynchronous argument-vector reads with line limits, request timeouts, bounded concurrency, and partial-failure handling; verify timeout, malformed response, pane closure, and successful sibling reads through transport tests.
- [x] 2.4 Add bounded context-aware caching, in-flight deduplication, expiry, and obsolete-request suppression; verify connection/tab/settings isolation and out-of-order completions with controlled asynchronous tests.

## 3. Completion behavior

- [x] 3.1 Implement terminal-text cleanup, candidate extraction, deduplication, fuzzy filtering, result limits, and search escaping; verify non-contiguous matches, repeated words, control sequences, and search delimiters in focused tests.
- [x] 3.2 Implement source availability and score-aware comparator with stable ties; verify inactive behavior outside Herdr, callback completion on failures, and ordering within Herdr results without comparing scores from other sources.
- [x] 3.3 Document defaults, bounded history semantics, global setup, per-source overrides, explicit-pane selection, and visible-only capture; verify examples against the implemented option names and a minimal cmp configuration.

## 4. KoalaVim integration and delivery

- [x] 4.1 Add the Herdr plugin dependency alongside fuzzy-buffer and pair the sources in general, search, debug-watch, and Cargo.toml configurations; verify evaluated source tables contain both entries, correct limits/priorities, and unchanged colon completion.
- [x] 4.2 Register the Herdr comparator and verify live cmp behavior with both buffer and Herdr candidates, including insert confirmation and escaped search completion; run applicable Lua formatting and plugin headless tests.
- [x] 4.3 Smoke-test same-tab scrollback completion, global and source-specific overrides, tab switching, and operation outside Herdr using a local development checkout; record outcomes and ensure the standalone repository is available before shipping the remote dependency.

## Verification results

- Standalone plugin created and pushed to https://github.com/KoalaVim/cmp-fuzzy-herdr at `cc26721`. Local checkout is the sibling `../cmp-fuzzy-herdr`.
- `make test` passed: 16 focused tests with the real fzy backend and cmp registration, plus real cmp event-loop verification of both source priorities, insert confirmation, and escaped search confirmation. Controlled topology changes verified cache isolation when pane tab membership changes.
- `dev/test-cmp-fuzzy-herdr.lua` passed: evaluated KoalaVim dependencies, all four source configurations, priorities, comparator, and unchanged colon completion.
- Live Herdr 0.8.2 capture verified a unique word above the viewport, visible-only exclusion, global explicit-pane settings, and per-source overrides. The temporary test pane was closed afterward.
- Source availability outside Herdr, malformed metadata, timeouts, partial reads, obsolete requests, and connection changes passed controlled tests.
- Lua formatting and diff whitespace checks passed.
