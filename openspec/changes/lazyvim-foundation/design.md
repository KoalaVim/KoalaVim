## Context

Today's boot sequence (KoalaConfig.template):

```
init.lua
 ├─ koala_init.load_koala(leader)   → bootstrap KoalaVim → KoalaVim.init()
 │     └─ recursive_require('config', 'KoalaVim')     (Koala options/keymaps/autocmds)
 ├─ recursive_require('config')                        (user config, all files)
 └─ koala_init.load_lazy({ user_spec, lazy_opts })
       └─ lazy.setup({ spec = user_spec ++ KoalaVim.spec })   ← user spec FIRST
             └─ KoalaVim plugin config(): conf.load(), state:load(), modes
```

`kvim.conf` becomes available only inside the KoalaVim plugin's `config`, after all specs are resolved, so nothing spec-level can depend on it. LazyVim expects a different shape. `lazyvim.plugins` must be the first import, and LazyVim loads `lazyvim.config.options` at import time (`require("lazyvim.config").init()`). It then loads `config.options` / `config.keymaps` / `config.autocmds` from the user's runtimepath itself, on its own schedule (options immediately, keymaps on VeryLazy, autocmds immediately or on VeryLazy).

`koala_init.lua` lives in the user's config ("DO NOT EDIT") and is shipped by the template and kv, so changing it needs a migration path.

## Goals / Non-Goals

**Goals:**
- KoalaVim spec layers on LazyVim with a fixed import order: `lazyvim.plugins` → KoalaVim's required extras → `KoalaVim.plugins` → user `plugins`.
- `kvim.conf`, including `flavor`, is readable while specs are being resolved.
- A single, documented load order for options/keymaps/autocmds: LazyVim → KoalaVim → user.
- Treesitter, which-key, the colorscheme and the snacks misc modules come from LazyVim, with KoalaVim additions.

**Non-Goals:**
- LSP, formatting, linting, DAP: covered by `lazyvim-lsp-formatting`.
- Completion and snippets: covered by `lazyvim-completion`.
- Plugin-by-plugin UI/editing swaps and flavor-specific plugin selection: covered by `lazyvim-ui-editing`.
- Any keymap conflict resolution: covered by `flavor-keymaps`. In this phase LazyVim's and KoalaVim's keymaps simply coexist. KoalaVim's wins where both set the same key, because it loads later.

## Decisions

### D1. Spec layer, not fork
`KoalaVim.spec` returns:
```lua
{
  { 'LazyVim/LazyVim', import = 'lazyvim.plugins', opts = { colorscheme = 'ofirkai', news = { lazyvim = true } } },
  -- extras KoalaVim depends on (added by later phases)
  { import = 'lazyvim.plugins.extras.…' },
  { 'KoalaVim/KoalaVim', import = 'KoalaVim.plugins' },
  -- hydras / lsp.servers imports as today
}
```
`koala_init.load_lazy` must append `user_spec` **after** the KoalaVim spec (it currently prepends it). User extras picked with `:LazyExtras` are imported by `lazyvim.plugins.xtras`, which is part of `lazyvim.plugins`, so they still come before KoalaVim. LazyVim's import-order check only looks for `^plugins$` and stays quiet.

`lazyvim.plugins.xtras` also auto-imports LazyVim's **default extras** (`coding.blink`, `editor.snacks_picker`, `editor.snacks_explorer`), chosen by `vim.g.lazyvim_cmp` / `lazyvim_picker` / `lazyvim_explorer`. LazyVim's `options.lua` resets those globals to `"auto"`, so KoalaVim sets them in its options layer (D4), not before `lazy.setup`. This phase sets `vim.g.lazyvim_cmp = 'nvim-cmp'`, because blink's extra disables nvim-cmp and would silently replace KoalaVim's completion. The picker and explorer defaults are left to `lazyvim-ui-editing`.

Where a LazyVim spec reaches a KoalaVim plugin that later phases replace, this phase stops the crash:
- `vim.g.trouble_lualine = false`: LazyVim's lualine opts call `trouble.statusline`, which KoalaVim's trouble v2 fork lacks.
- KoalaVim's alpha fork is renamed in lazy.nvim (`name = 'koala-alpha-nvim'`), so LazyVim's optional `goolord/alpha-nvim` fragments (e.g. the snacks_picker "Projects" button) don't merge into it.
*Alternative:* fork LazyVim. Rejected because every upstream release would need a rebase.
*Alternative:* use only the `LazyVim.*` utilities without the specs. Rejected because it loses LazyVim's preconfigured plugins.

### D2. kvim.conf loads in `KoalaVim.init()`
`KoalaVim.init()` already runs before `lazy.setup`. Move `conf.load()` there, together with `conf.reg_autocmd()` and `state:load()` if they are safe that early. Keep the KoalaVim plugin `config` for anything that needs plugins loaded (koala modes). `require('KoalaVim').conf` is then valid inside every spec module, `opts` function, `enabled`/`cond` function and `keys` table. Modules used this early must not require plugins at the top level. `KoalaVim.health` loaded fidget eagerly; it now loads it lazily and falls back to `vim.notify`.
*Alternative:* read conf lazily inside the first `KoalaVim.plugins` module. Rejected as fragile because it depends on import order.

### D3. Flavor helper
`require('KoalaVim.flavor')` exposes `get()` → `'koala'|'lazyvim'` (validated, falls back to `'koala'` with a health warning), plus `is(name)` and a `pick({ koala = …, lazyvim = … })` helper for opts/keys. The value is read once from the loaded conf and is not reloaded at runtime; changing flavor requires a restart.

### D4. Options / keymaps / autocmds order
- Register `User LazyVimOptionsDefaults`, `LazyVimKeymapsDefaults` and `LazyVimAutocmdsDefaults` listeners in `KoalaVim.init()`, before `lazy.setup`, because options load while `lazyvim.plugins` is imported. Each listener requires the matching `KoalaVim.config.*` module.
- The user's `config/options.lua`, `config/keymaps.lua` and `config/autocmds.lua` are loaded by LazyVim itself, after the Defaults event, so they still override KoalaVim. The template's `init.lua` stops recursively requiring `config/`, which would otherwise load them twice. User `config/` files with other names (e.g. `usercmds.lua`) are loaded by KoalaVim on the `LazyVimKeymaps` event (after the user's keymaps). `config_lazy/*` stays on lazy.nvim's `LazyVimStarted` and keeps firing `KoalaVimStarted`.
- KoalaVim's own `config/keymaps/*.lua` and `config/autocmds/*.lua` become modules aggregated by `KoalaVim.config.keymaps` / `KoalaVim.config.autocmds`.
- The options listener runs while lazy.nvim imports `lazyvim.plugins`. lazy.nvim has reset the runtimepath by then, so the listener prepends the KoalaVim root to `rtp` before requiring `KoalaVim.config.options` (LazyVim does the same for itself).
- LazyVim's `options.lua` overwrites `mapleader`/`maplocalleader`. `init()` remembers the leaders set by `koala_init.load_koala` and restores them on `LazyVimOptionsDefaults`.
- KoalaVim's options first reset every option that LazyVim sets and KoalaVim doesn't (clipboard, conceallevel, laststatus, completeopt, …) to Neovim's default, keeping KoalaVim's previous behavior. KoalaVim's autocmds delete LazyVim's `lazyvim_highlight_yank` (duplicate) and `lazyvim_wrap_spell` (KoalaVim owns spell filetypes) groups.
- **Load timing (breaking):** the user's other `config/**` files, and KoalaVim's and LazyVim's keymaps, run at VeryLazy instead of during `init.lua`. Autocmds also run at VeryLazy when nvim starts with no file arguments. Users whose config must run early should move it to `config/options.lua`.
- `koala_init.load_lazy` sets `vim.g.koala_init_version = 2`. The old-layout warning (D5) fires on `LazyVimStarted` when it's missing.
*Alternative:* `defaults.keymaps = false` and keep KoalaVim's own order. Rejected here because that decision belongs to the keymaps phase (koala flavor only).

### D5. Template / kv migration
Ship the new `koala_init.lua` (user spec appended, no recursive `config` require) in KoalaConfig.template and the kv starter. On startup, `KoalaVim.init()` detects the old layout (a user spec placed before the KoalaVim spec, or a double config load), keeps working, and shows a health warning with migration steps.

### D6. Treesitter
Take LazyVim's `nvim-treesitter` (main) spec. KoalaVim adds parsers through `opts.ensure_installed` (opts_extend), plus endwise, matchup, jsonpath and treesitter-context (KoalaVim's spec; the LazyVim `ui.treesitter-context` extra is not enabled), and the `sidekick_koala_prompt` → markdown language registration. KoalaVim's per-buffer fold/indent logic is dropped, because LazyVim's `folds`/`indent` FileType hook covers it. One KoalaVim feature stays: **on-demand parser install**. Opening a filetype whose parser isn't installed installs it, then starts treesitter and sets LazyVim's `indentexpr`/`foldexpr` on the buffer. KoalaVim's explicit parser list is added to LazyVim's `ensure_installed`. The textobjects spec keeps KoalaVim's own `config` and global maps. LazyVim's `]c`/`[c`/`]C`/`[C` class moves are set to `false`, because they lack LazyVim's diff-mode guard and conflict with hunk navigation.

Incremental selection is a small KoalaVim util that walks `vim.treesitter.get_node()` parents and keeps a per-buffer selection stack. The stack stays valid only while `changedtick` and the visual range match its top. It is mapped to `<C-Space>` (start/expand, normal and visual) and `<BS>` (shrink, visual), not `<CR>`, because visual `<CR>` copies to the OS clipboard. Until `lazyvim-ui-editing` disables flash, flash's own `<C-Space>` treesitter selection shadows these keys.

### D7. which-key and colorscheme
Remove KoalaVim's which-key spec and take LazyVim's. Group labels that conflict with KoalaVim keys (`<leader>c`, `<leader>d`, `<leader>b`, `<leader>s`, `gs`) are left as-is in this phase; `flavor-keymaps` reconciles them. Colorscheme: `opts.colorscheme = 'ofirkai'`. KoalaVim's ofirkai spec stays non-lazy with priority 1000 and its `theme = 'dark_blue'` opts. LazyVim applies the colorscheme with `:colorscheme ofirkai`, and ofirkai's `colors/ofirkai.vim` called `setup({})`, resetting the theme to the default palette. ofirkai now remembers the last `setup()` config and `colors/ofirkai.vim` re-applies it.

### D8. Snacks misc modules
Merge KoalaVim's snacks opts into LazyVim's (both are `folke/snacks.nvim` specs). Keep KoalaVim's explicit `enabled = false` only for the modules later phases turn off (`dashboard`, `explorer`, `indent`, `input`, `statuscolumn`, `words`), plus `scope`. `scope` adds `ii`/`ai` textobjects that clash with KoalaVim's treesitter `ii`/`ai` (conditional). Leave `bigfile`, `quickfile`, `scroll` and `notifier` enabled.

### D9. Lockfile generator
`dev/gen_lockfile_init.lua` resolves `KoalaVim.spec` outside a normal startup, so it has to recreate what LazyVim's import needs:
- prepend LazyVim to `rtp`, since `lazyvim.plugins` requires `lazyvim.config` while being imported
- load `KoalaVim.config.options` on `LazyVimOptionsDefaults`, so default-extra globals such as `lazyvim_cmp` match a real startup
- point `vim.g.lazyvim_json` at a non-existent temp file, so the developer's `:LazyExtras` choices don't leak into the shared lockfile

Without these, LazyVim's core plugins and extras silently drop out of the lockfile.

## Risks / Trade-offs

- [The two snacks specs' opts merge unpredictably (KoalaVim's picker layout vs LazyVim's)] → Keep KoalaVim's snacks spec after LazyVim's (guaranteed by import order) and use an `opts` function where table merge isn't enough.
- [snacks `scroll` animates every recenter (`nzz`, `<C-o>zz`) and fights scrollofffraction/smear-cursor] → Accepted for now. Note it in the docs and revisit; `<leader>uS` toggles it.
- [Existing user configs on the old `koala_init.lua` load user config twice or in the wrong order] → Detect in `init()`, warn with migration steps, and update the template and kv starter in the same release.
- [LazyVim's option defaults (e.g. `clipboard=unnamedplus`, `conceallevel=2`, `relativenumber`, `laststatus=3`) change behavior where KoalaVim's options don't override them] → Audit `lazyvim.config.options` against `KoalaVim.config.options` and set explicit values where KoalaVim wants its previous behavior.
- [LazyVim's keymaps now exist alongside KoalaVim's until `flavor-keymaps` lands] → Ship phases 1–5 together on the `over-lazyvim` branch; don't release phase 1 alone.

## Migration Plan

1. Land on the `over-lazyvim` branch; regenerate `lazy-lock.json` with LazyVim pinned.
2. Update KoalaConfig.template and the kv starter (`koala_init.lua`, `init.lua`).
3. Release only after all five phases are complete.

## Open Questions

- Can `state:load()` and `conf.reg_autocmd()` move into `init()` safely? Both touch only files and autocmds, so probably yes. Verify during implementation.
- Should KoalaVim pin a LazyVim release tag or a commit (via the lockfile, either way)?
