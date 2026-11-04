# KoalaVim

KoalaVim is a meta-config on top of [LazyVim](https://github.com/LazyVim/LazyVim). LazyVim provides the framework (loader,
`LazyVim.*` utils, extras, opts merging) and the plugins it does better. KoalaVim replaces or extends the rest.
This file covers how the two fit together and what breaks if you ignore it.

Further reading:

- `docs/decisions/lazyvim-migration.md`: the decision log (D1–D62), why each system went the way it did.
- `openspec/changes/*/design.md`: per-area design. The "Implementation notes (as built)" sections take precedence over
  the decisions above them. These move to `openspec/changes/archive/` once archived.
- `docs/keymaps.md`: the per-flavor cheat sheet (generated, don't edit).

LazyVim's source is at `../LazyVim` from this checkout, at the commit pinned in `lazy-lock.json`. Read it there rather
than from memory: most mistakes here come from assuming how a LazyVim spec is built.

## Load order

`init.lua` of the user's config (`KoalaConfig.template`) calls `koala_init.load_koala()`, then `koala_init.load_lazy()`.

1. `KoalaVim.init()` (`lua/KoalaVim/init.lua`) runs **before** `lazy.setup`. It loads kvim.conf, validates the flavor and
   registers the listeners for LazyVim's `User` events. Specs can read `require('KoalaVim').conf`.
2. `lazy.setup` resolves the specs, in the order of `lua/KoalaVim/spec.lua`, then the user's:
   1. `lazyvim.plugins`, including LazyVim's default extras
   2. the extras KoalaVim depends on (`dap.core`, `editor.illuminate`, `lang.*`)
   3. `KoalaVim.plugins`, then the hydras, `plugins/lsp/servers`, `plugins/lsp`
   4. the user's `plugins`
3. Config files layer in this order: LazyVim's, then KoalaVim's (`LazyVim{Options,Keymaps,Autocmds}Defaults` events,
   `lua/KoalaVim/config/`), then the user's `config/`.
   - Options load while lazy.nvim imports `lazyvim.plugins`, so KoalaVim isn't on the runtimepath yet.
     `init.lua` prepends it first.
   - `config/options.lua` resets LazyVim options KoalaVim doesn't set back to Neovim's defaults.
   - The user's `config/**` files LazyVim doesn't load by itself are loaded on `User LazyVimKeymaps`.
4. On `LazyVimStarted`: `config_lazy/`, then `User KoalaVimStarted`.

A config without `vim.g.koala_init_version` (the old bootstrap) gets a migration warning.

## How to decide who owns a plugin

One owner per concern. Each KoalaVim spec is one of:

- **Take**: LazyVim's spec, with at most small `opts` tweaks. Examples: which-key, snacks core, trouble, mini.ai.
- **Keep**: KoalaVim's plugin, LazyVim's equivalent gets `enabled = false` in `plugins/lazyvim.lua`.
  Examples: leap (flash), nvim-autopairs (mini.pairs), Comment.nvim (ts-comments), spectre (grug-far),
  nvim-tree (snacks explorer).
- **Fuse**: LazyVim's plugin and mechanism, with KoalaVim layered through `opts` or hooks. Examples: nvim-lspconfig,
  conform, nvim-cmp, noice, gitsigns, `LazyVim.pick` (routed to fff for files and grep, see `utils/pick.lua`).

Don't add a second plugin for a concern that already has an owner. Check the decision log first.

## Flavors

`flavor` in kvim.conf is `koala` (default) or `lazyvim`. It's read once, so changing it needs a restart.

| Concern | koala | lazyvim |
|---|---|---|
| Keymap layout | KoalaVim's wins | LazyVim's wins |
| Statusline, tabline | KoalaVim's | LazyVim's, with the ofirkai theme |
| Dashboard | alpha | snacks, with KoalaVim's buttons |
| Sessions | possession | persistence |
| Terminal | toggleterm + term-edit | snacks + term-edit |

Use `require('KoalaVim.flavor')`:

- `is(name)` for gating plugins. Use it in `enabled`, because it returns true for **both** flavors in the lockfile
  generator, so the lockfile covers both plugin sets.
- `pick({ koala = a, lazyvim = b })` for picking a value. It uses the real flavor, so don't gate `enabled` with it.
- `get()` before kvim.conf loads returns the default without caching it.
- To keep LazyVim's `config` in the lazyvim flavor, use `config = flavor.is('koala') and fn or nil`.

Use the `User KoalaDashboardClosed` event, not `AlphaClosed`, and `utils/session.lua`, not a session backend directly.

## Keymaps

All contested keys live in `lua/KoalaVim/keymaps/contested.lua`, the single source for the engine (`remap.lua`), the
helpers and the checker (`check.lua`). A contested key is one LazyVim and KoalaVim both bind, or one LazyVim binds on a
Vim default.

- A key that LazyVim might bind, or that duplicates a LazyVim action, goes through `kkeys` (plugin `keys`), `kmap` /
  `kmap_buffer` (`utils/map.lua`) or `klhs`. They're always safe to use: a key not in the table is defined as is.
- Add the contested entry first, then bind the key. `win` pins one winner in both flavors. The loser gets `to` or `drop`.
- `desc` in a `Side` is how `check()` tells who owns a key at runtime. If you change a mapping's description, update it.
- When a LazyVim bump or a new extra adds keys to a plugin, add that plugin to `plugins` in `plugins/lazyvim_keys.lua`.
- Run `make test-keymaps` and `make gen-keymaps-doc` after any key change. `:checkhealth KoalaVim` runs the same check.

## Language setup

- Language packs are LazyVim's `lang.*` extras. `plugins/lsp/servers/*.lua` are small deltas on `opts.servers`, not a
  separate registry. The old `LSP_SERVERS` / `CONFORM_FORMATTERS` globals only exist as a compatibility shim.
- Formatting is `LazyVim.format` + conform. Declare `formatters_by_ft` and mason's `ensure_installed` next to the
  language. `utils/lsp.lua` (`setup_format()`) applies the kvim.conf blacklists on top. AutoSave writes don't format.
- `servers["*"]` holds what applies to every server: stripping semantic tokens and `labelDetailsSupport = false`.
- Completion is nvim-cmp with native snippets. KoalaVim's snippets are VSCode JSON in `snippets/`; each file must be
  listed in `snippets/package.json`.

## Caveats

### lazy.nvim

- **`init` and `config` aren't merged across fragments**, the last one wins. KoalaVim owns `init` on `LazyVim/LazyVim`
  (format policy), `KoalaVim/diagflow.nvim`, `nvim-dap`, `nvim-lspconfig` and `snacks.nvim` (dashboard, in `ui.lua`). If
  you add an `init` to one of these, call the existing hook. KoalaVim's dap-ui `config` fully replaces the extra's.
- **`keys = function(plugin, keys)` only sees fragments merged before it.** That's why KoalaVim's own lists use `kkeys`,
  which marks them so `remap.keys` leaves them alone. `plugins/lsp/keys.lua` must stay in the last import of `spec.lua`.
- **Extras must stay between `lazyvim.plugins` and `KoalaVim.plugins`** in `spec.lua`. A later import can't be overridden
  by KoalaVim's specs.
- Spec fragments that only adjust a plugin should use `optional = true`, or they enable it on their own.

### LazyVim

- **LazyVim's `options.lua` resets `vim.g.lazyvim_*`.** Set them in `lua/KoalaVim/config/options.lua`, not earlier.
- **Default extras are chosen by those globals.** Without `vim.g.lazyvim_cmp = 'nvim-cmp'`, the default blink extra
  silently disables nvim-cmp. `vim.g.lazyvim_explorer` only accepts snacks or neo-tree, so the explorer is disabled with
  snacks' `explorer.enabled = false` plus `{ lhs, false }` key fragments.
- **`LazyVim.lsp.formatter()` can't exclude clients.** `setup_format()` wraps `LazyVim.format.register` instead. Blacklisted
  conform formatters get a composed `condition` rather than being removed from `formatters_by_ft`, which keeps
  `stop_after_first` working. `gq` and `<leader>cF` bypass the filetype guard but still respect `format.blacklist`.
- **LazyVim's global keymaps use `safe_keymap_set`**, which skips a key already held by a lazy `keys` stub. Keys moved onto
  such a spot go through `adds` in `contested.lua` (`<leader>zz/zl/zx`).
- **LazyVim also creates keys later** from plugin `config`, ftplugins and LSP attach. `remap.watch()` re-sweeps on
  `FileType`, `LspAttach` and `User LazyLoad`, and only touches maps whose callback lives in `lazyvim/`.
- `utils/pick.lua` wraps `LazyVim.pick.picker.open`, a LazyVim internal. Recheck it on LazyVim bumps.
- **Pins move together.** LazyVim calls newer snacks APIs than an old snacks pin has. After a bump, check the `Snacks.*`
  calls in LazyVim against the pinned snacks.

### Server and plugin specifics

- The `servers["*"].on_init` semantic-tokens strip doesn't cover gopls, because LazyVim's workaround re-adds the provider
  on attach. gopls also sets `init_options.semanticTokens = false`.
- Unwanted servers need `enabled = false`, since mason-lspconfig's `automatic_enable` starts any installed server.
- noice stops at the first matching route, so KoalaVim's routes go **before** LazyVim's.
- The pinned nvim-lspconfig has no `tsc` server, so KoalaVim defines its `cmd` and `root_markers`.
- The python extra doesn't install debugpy, so KoalaVim keeps it in mason's `ensure_installed`.
- mason-nvim-dap has no-op handlers for `codelldb` and `cppdbg`, or it replaces KoalaVim's adapters. The remote delve
  adapter is named `go_remote` so it doesn't clobber dap-go's `go`.
- dap-ui's close handler runs on `terminated`, `exited` **and** session close (`on_session`). `disconnect` can drop the
  first two, so all three are needed; the handler tracks the tab handle so it closes only once.
- `vim.snippet` doesn't parse a variable inside a placeholder default (`${1:${TM_FILENAME_BASE}}`) and ignores `/upcase`
  transforms. Use a bare variable.
- persistence must be `lazy = false`, otherwise its `BufReadPre` trigger misses the startup disable controls. It has no
  named sessions. Sessions saved under one backend aren't visible after switching flavor.
- cmp-fuzzy-dictionary's `reload` is in `after/plugin`, which lazy.nvim doesn't source during startup. Its config does.
- go.nvim is disabled, so its settings and keys in `servers/go.lua` are dead code.
- On macOS, build C/C++/Rust through real paths. A binary built via `/tmp` (a symlink to `/private/tmp`) never stops at
  breakpoints: lldb matches the literal path, and Neovim resolves symlinks.

### Keymap checks

- `check()` can't see two sources setting the same key when only one is in the table.
- `make test-keymaps` runs lua, go, rust, markdown and C buffers. Python, TypeScript and Zig filetype entries are
  unverified. A server that isn't installed is skipped and reported.

### Pending cleanup

- `plugins/ui.lua` pins ofirkai to `branch = 'feat/lazyvim'`. Remove the pin once that branch merges into ofirkai's
  master. Commit ofirkai work to a branch, not to master.
- `docs/plugins/*` and `.luarc.json` predate the migration and may be stale.

## Development

- `make dev-setup` enables `hooks/`. Lua is formatted with stylua (`stylua.toml`).
- `make test-keymaps`: both flavors, needs `kv` and a KoalaVim env.
- `make gen-keymaps-doc`: regenerates `docs/keymaps.md`. The group prose is hand-written in `scripts/gen_keymaps_doc.lua`.
- `make gen-types`: regenerates the LuaLS types from `config_scheme.jsonc`.
- Changes are planned with OpenSpec (`openspec/`, skills in `.claude/skills`).

### The pre-commit hook

It stashes unstaged and untracked work, regenerates `lazy-lock.json` through `dev/gen_lockfile_init.lua`, stages it, then
pops the stash.

- The `kv` env name comes from the path, so the checkout must be at `~/.local/share/kvim-envs/<env>/lazy/KoalaVim`.
- If your unstaged `lazy-lock.json` differs on the same lines, the stash pop conflicts. Commit or regenerate it first.
- The generator uses only `default_kvim.conf`, ignores `lazyvim.json` and keeps the entries of plugins missing from disk,
  so the result doesn't depend on your personal config.

### Headless testing

```sh
env -u KOALA_MODE -u KOALA_ARGS -u KOALA_NO_SESSION -u NVIM_APPNAME -u KV_ENV -u NVIM \
  KOALA_NO_SESSION=1 kv --env <env> --cfg <empty.conf> -- --headless "+luafile probe.lua"
```

- Unset the inherited `KOALA_*` and `NVIM*` variables. A leaked `KOALA_MODE` starts a mode such as the AI picker instead of a plain session.
- Pass an empty `--cfg`: `~/.kvim.conf` applies otherwise, and something like a filetype blacklist invalidates the result.
- `UIEnter` doesn't fire headless, so fire it manually when a probe needs what loads after it.
- Don't wrap `vim.notify` in a probe, it can hang startup.
- macOS has no `timeout` binary. Use a kill loop, as `dev/test_keymaps.sh` does.
