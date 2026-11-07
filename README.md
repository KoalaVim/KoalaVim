<img src="https://github.com/KoalaVim/KoalaVim/assets/4954051/bfdd2db9-1957-4a7f-8ada-f561f2ec5860" align="right" width="350" />

# KoalaVim

Batteries-included, extensible Neovim distribution — curated plugins, robust defaults, and terminal-first tooling. Powered by [lazy.nvim](https://github.com/folke/lazy.nvim) and managed by [`kv`](https://github.com/KoalaVim/kv).

<br><br><br><br><br><br>

---

## 🚧 KoalaVim is in early alpha. Expect breaking changes. 🚧

## Features

- Improved AI integration over [sidekick.nvim](https://github.com/folke/sidekick.nvim) — in-buffer edit-prompt, prompt navigation, zoom-to-tabpage, sticky default-tool selector, and fast-typing auto-edit detection.
- Git-aware launch modes (diff, status, tree).
- Modal sub-modes via [Hydra](docs/plugins/hydra.md).
- Curated plugin set across 16 categories — see [`docs/plugins/`](docs/plugins/README.md).
- Isolated virtual environments via [`kv`](https://github.com/KoalaVim/kv).
- JSON-schema-validated user config.

## Integrations
- [herdr aware plugin](https://github.com/KoalaVim/herdr-nvim-aware) — [example herdr config](external-configs/herdr-config.toml)

### Recommended mux bindings (Herdr)

The [example Herdr config](external-configs/herdr-config.toml) provides these bindings:

| Key | Action |
| --- | --- |
| `Ctrl+h/j/k/l` | Navigate Neovim splits or Herdr panes. |
| `Alt+e/o` | Split vertically/horizontally. |
| `Alt+w/q` | Close the split/pane. |
| `Alt+z` | Toggle zoom. |
| `Alt+a` (`<M-a>`) | Hide the attached Sidekick-created agent pane by zooming Neovim. The agent keeps running. Other panes receive Alt+A normally. |

For `Alt+a`, install the helper from your KoalaVim checkout:

```bash
mkdir -p "$HOME/.local/bin"
ln -s "$PWD/bin/sidekick-herdr-minimize" "$HOME/.local/bin/sidekick-herdr-minimize"
```

Add this binding to your Herdr config, then reload it:

```toml
[[keys.command]]
key = "alt+a"
type = "shell"
command = '"$HOME/.local/bin/sidekick-herdr-minimize"'
```

## Requirements

- Neovim ≥ v0.12.0
- A [Nerd Font](https://www.nerdfonts.com/)
- A terminal with true-color and undercurl support — [kitty](https://github.com/kovidgoyal/kitty), [wezterm](https://github.com/wez/wezterm), [ghostty](https://ghostty.org/), [alacritty](https://github.com/alacritty/alacritty), or [iterm2](https://iterm2.com/)

Tool dependencies (ripgrep, fd, fzf, …) are installed automatically by `kv install`.

## Installation

### Recommended: with `kv`

[`kv`](https://github.com/KoalaVim/kv) is the KoalaVim launcher and environment manager. Install it first — see the [kv README](https://github.com/KoalaVim/kv#installation) for instructions.

Then bootstrap a KoalaVim environment, either via the interactive wizard:

```bash
kv init
```

…or directly from the starter template:

```bash
kv env create main --from https://github.com/KoalaVim/KoalaConfig.template
```

Launch KoalaVim:

```bash
kv
```

### Manual Install (Not Recommended)

If you'd rather not use `kv`, you can install KoalaVim into the standard Neovim config location.

> [!NOTE]
> You'll need to install tool dependencies yourself — at minimum `ripgrep`, `fd`, and `fzf`. See the [kv install docs](https://github.com/KoalaVim/kv/blob/main/docs/install.md) for the full list.

Back up your existing Neovim config and data directories:

```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
```

Clone the [KoalaConfig template](https://github.com/KoalaVim/KoalaConfig.template) into `~/.config/nvim`:

```bash
git clone https://github.com/KoalaVim/KoalaConfig.template ~/.config/nvim
rm -rf ~/.config/nvim/.git   # optional: remove if you plan to push it as your own
```

Launch Neovim:

```bash
nvim
```

The first launch installs all treesitter parsers and may be laggy. Restart Neovim after the installation completes.

## Configuration

The common knobs are exposed via `kvim.conf` (JSON) at your config root. Full schema: [`config_scheme.jsonc`](config_scheme.jsonc). The [KoalaConfig template](https://github.com/KoalaVim/KoalaConfig.template) is a working starter.

Example `kvim.conf`:

```json
{
  "editor": {
    "indent": { "tab_size": { "min": 2, "max": 4 } }
  },
  "ai": {
    "default_tool": "claude"
  },
  "ui": {
    "statusline": { "icons_only": false }
  }
}
```

### Config layers

KoalaVim deep-merges `.kvim.conf` layers; later layers override earlier ones:

1. KoalaVim defaults (`default_kvim.conf`)
2. user conf (`~/.kvim.conf`, or the path in `KOALA_KVIM_CONF`)
3. env conf (the path in `KOALA_ENV_KVIM_CONF`, set by `kv` to `<env config dir>/.kvim.conf`)
4. repo conf (`<git toplevel>/.kvim.conf`)

The env conf is optional and never created automatically. Without `kv` (`KOALA_ENV_KVIM_CONF` unset) it is skipped. Use the dashboard button `kec` ("Koala Env Config") or `kv env config` to edit it.

### Advanced configuration

JSON only covers what's been exposed. For anything beyond — extra plugins, custom keymaps, lazy.nvim option overrides — your config root is a regular Lua project that extends KoalaVim:

- `lua/plugins/*.lua` — your own [lazy.nvim plugin specs](https://lazy.folke.io/spec). Merged with KoalaVim's spec at startup.
- `lua/config/*.lua` — options, keymaps, autocmds, usercmds. Loaded after KoalaVim's config, so it can override anything.
- `lua/config_lazy/*.lua` — same as above but loaded after lazy.nvim finishes (`KoalaVimStarted` event).
- `lazy_opts` in `init.lua` — override lazy.nvim setup options (e.g. default colorscheme).

See the [KoalaConfig template](https://github.com/KoalaVim/KoalaConfig.template) for a working `init.lua` and examples of each.

## Plugins

Plugins are organized by category. See [`docs/plugins/README.md`](docs/plugins/README.md) for the full index with upstream links and per-plugin descriptions.

## Contributing

- Setup dev environment (git hooks):

  ```bash
  make dev-setup
  ```

- Lua formatting via [`stylua`](https://github.com/JohnnyMorganz/StyLua) (config: [`stylua.toml`](stylua.toml)).
- Local development: create a scratch env pointing at your local KoalaVim checkout, e.g. `kv env create dev --from <path>`, or fork an existing env. See [kv env docs](https://github.com/KoalaVim/kv/blob/main/docs/envs.md).

## License

Licensed under [GPL-3.0](LICENSE).
