## Why

KoalaVim maintains its whole framework by hand: config loading, option/keymap/autocmd defaults, the which-key setup, the theme bootstrap and treesitter management. LazyVim already provides a mature, maintained version of all of these (opts merging, extras, `LazyVim.*` utilities, toggles, root detection). Rebuilding KoalaVim as a layer on top of LazyVim lets it inherit that work while keeping KoalaVim's own features. This change lays the foundation every later phase builds on.

## What Changes

- KoalaVim's lazy spec imports `lazyvim.plugins` first, then the LazyVim extras KoalaVim needs, then `KoalaVim.plugins`, then the user's `plugins`. LazyVim is a pinned dependency in KoalaVim's deterministic `lazy-lock.json`, not a fork.
- **BREAKING**: `kvim.conf` is loaded during bootstrap, **before** lazy.nvim resolves specs (today it loads in the KoalaVim plugin's `config` hook). Spec-level choices such as flavor, `vim.g.lazyvim_*` and `enabled`/`keys` can then depend on it.
- New global `flavor` setting in `kvim.conf` (`"koala" | "lazyvim"`, default `"koala"`). Later phases use it to choose between KoalaVim's and LazyVim's version of keymaps, statusline/bufferline, dashboard, sessions and terminal.
- LazyVim's options, keymaps and autocmds load first. KoalaVim's `config/*` is applied on LazyVim's `User LazyVim{Options,Keymaps,Autocmds}Defaults` events, before the user's `config/*.lua`. KoalaVim's `config_lazy/*` and the `KoalaVimStarted` event are kept.
- ofirkai is set as LazyVim's colorscheme.
- which-key comes from LazyVim's spec (groups, `<leader>?` buffer keymaps). KoalaVim's empty which-key spec is removed.
- Treesitter comes from LazyVim's spec (main branch, `LazyVim.treesitter` install/fold/indent). KoalaVim adds endwise, matchup, jsonpath, treesitter-context, the `sidekick_koala_prompt`→markdown registration and a working incremental-selection implementation (the current `<CR>`/`<BS>` keys are description-only stubs).
- The snacks `bigfile`, `quickfile`, `scroll` and `notifier` modules are enabled as LazyVim configures them.
- Users can add extras with `:LazyExtras` (stored in `lazyvim.json` in their kv env config). LazyVim's NEWS popup stays enabled.
- `require_dir`'s `fd`/`ls` popen scanning is replaced with `vim.fs.dir`.

Later phases: `lazyvim-lsp-formatting`, `lazyvim-completion`, `lazyvim-ui-editing`, `flavor-keymaps`. Each depends on this change.

## Capabilities

### New Capabilities
- `lazyvim-base`: How KoalaVim layers on LazyVim. Spec import order, pinned LazyVim, required extras, user extras with `:LazyExtras`, LazyVim news, and the load order of options/keymaps/autocmds between LazyVim, KoalaVim and the user.
- `flavor`: The global `koala | lazyvim` flavor setting, its default, when it is read, and how specs query it.

### Modified Capabilities
- `core-framework`: The three-layer configuration must be available before plugin spec resolution. Module loading changes to run KoalaVim config modules on LazyVim's defaults events instead of a standalone recursive require at init.
- `ui`: The colorscheme is applied through LazyVim's colorscheme hook. which-key shows LazyVim's group labels.

## Impact

- `lua/KoalaVim/init.lua`, `lua/KoalaVim/spec.lua`, `lua/KoalaVim/conf.lua`, `lua/KoalaVim/plugins/koala.lua`, `lua/KoalaVim/utils/require_dir.lua`
- `lua/KoalaVim/plugins/ui.lua` (ofirkai, which-key), `lua/KoalaVim/plugins/treesitter.lua`, `lua/KoalaVim/plugins/editor.lua` (snacks opts)
- `config_scheme.jsonc`, `default_kvim.conf`, `lua/KoalaVim/types/conf.lua` (regenerated): new `flavor` key
- `lazy-lock.json`, `dev/gen_lockfile_init.lua`: add LazyVim
- KoalaConfig.template `init.lua`: bootstrap changes (call KoalaVim's bootstrap before `lazy.setup`)
- New dependency: `LazyVim/LazyVim` (+ its core plugins that KoalaVim doesn't disable in later phases)
- Neovim requirement unchanged (KoalaVim ≥ 0.12 is above LazyVim's ≥ 0.11.2)
