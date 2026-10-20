## 1. Bootstrap and early config

- [x] 1.1 Move `conf.load()` (and `conf.reg_autocmd()`, `state:load()` if safe) from the KoalaVim plugin `config` into `KoalaVim.init()`; keep koala-mode loading in the plugin `config`
- [x] 1.2 Add `flavor` (`"koala" | "lazyvim"`, default `"koala"`) to `config_scheme.jsonc` and `default_kvim.conf`; regenerate `lua/KoalaVim/types/conf.lua` (`make gen-types`)
- [x] 1.3 Add `lua/KoalaVim/flavor.lua` with `get()`, `is(name)`, `pick({ koala, lazyvim })`, plus validation and a health warning for invalid values
- [x] 1.4 Replace `require_dir` popen scanning (`fd`/`ls`) with `vim.fs.dir`

## 2. LazyVim spec layer

- [x] 2.1 Rewrite `KoalaVim.spec`: `LazyVim/LazyVim` + `import = 'lazyvim.plugins'` (opts: `colorscheme = 'ofirkai'`, `news.lazyvim = true`), then an extras slot, then `KoalaVim.plugins` and its existing sub-imports
- [x] 2.2 Update `koala_init.lua` in KoalaConfig.template and the kv starter: append `user_spec` after the KoalaVim spec; stop recursively requiring the user's `config/` from `init.lua`
- [x] 2.3 In `KoalaVim.init()`, detect the old bootstrap layout (user spec first / double config load) and report a health warning with migration steps
- [x] 2.4 Add LazyVim to `dev/gen_lockfile_init.lua` and regenerate `lazy-lock.json` with LazyVim pinned
- [x] 2.5 Verify `:LazyExtras` writes `lazyvim.json` in the kv env config dir and that user extras load before `KoalaVim.plugins`

## 3. Options, keymaps, autocmds order

- [x] 3.1 Register `User LazyVimOptionsDefaults` / `LazyVimKeymapsDefaults` / `LazyVimAutocmdsDefaults` listeners in `KoalaVim.init()` that load `KoalaVim.config.options` / `.keymaps` / `.autocmds`
- [x] 3.2 Turn `config/keymaps/*.lua` and `config/autocmds/*.lua` into modules aggregated by `KoalaVim.config.keymaps` / `KoalaVim.config.autocmds`
- [x] 3.3 Load the user's other `config/*.lua` files (not options/keymaps/autocmds) once, after the user's keymaps; keep `config_lazy/*` on `LazyVimStarted` and keep firing `KoalaVimStarted`
- [x] 3.4 Audit `lazyvim.config.options` against `KoalaVim.config.options`; set KoalaVim's values explicitly wherever it wants to keep its previous behavior (clipboard, conceallevel, laststatus, etc.)
- [x] 3.5 Audit `lazyvim.config.autocmds` against KoalaVim's autocmds for duplicates or conflicts (yank highlight, checktime, last location, close-with-q, wrap/spell filetypes)

## 4. Theme, which-key, snacks

- [x] 4.1 Keep the ofirkai spec (non-lazy, priority 1000, `theme = 'dark_blue'`); confirm LazyVim's colorscheme hook loads it and falls back to habamax on failure
- [x] 4.2 Remove KoalaVim's which-key spec; confirm LazyVim's which-key loads (group labels are reconciled in `flavor-keymaps`)
- [x] 4.3 Merge KoalaVim's snacks opts into LazyVim's: enable `bigfile`, `quickfile`, `scroll`, `notifier`; keep the picker config; keep `dashboard`/`explorer`/`indent`/`input`/`statuscolumn`/`words` disabled
- [x] 4.4 ofirkai repo: add highlight groups for which-key, mini.icons, mini.ai, snacks dashboard, trouble v3 (including the fork's `TroubleCursorLine`), snacks notifier

## 5. Treesitter

- [x] 5.1 Remove KoalaVim's `nvim-treesitter` core spec; add KoalaVim parsers via `opts.ensure_installed`
- [x] 5.2 Keep endwise, matchup, jsonpath, treesitter-context, ts-context-commentstring and textobjects specs as KoalaVim additions; register `sidekick_koala_prompt` → markdown
- [x] 5.3 Compare KoalaVim's per-buffer fold/indent hook with LazyVim's `folds`/`indent`; keep only what LazyVim doesn't cover
- [ ] 5.4 Implement incremental selection (treesitter node-parent walk with a per-buffer stack) on `<C-Space>` (start/expand) / `<BS>` (shrink in visual). Implemented; until `lazyvim-ui-editing` disables flash, flash's `<C-Space>` shadows it. Tick once flash is off.

## 6. Verify

- [x] 6.1 Clean start in a fresh kv env: no errors, no LazyVim import-order warning, ofirkai applied
- [x] 6.2 Each user config file runs exactly once (debug log); KoalaVim option values win over LazyVim's, and user values win over KoalaVim's
- [x] 6.3 `flavor = "lazyvim"` in a repo `.kvim.conf` is visible to `require('KoalaVim.flavor').get()` inside a spec `enabled` function
- [x] 6.4 Startup modes (`KOALA_MODE` git/ai/diff) still work
