<img src="https://github.com/KoalaVim/KoalaVim/assets/4954051/bfdd2db9-1957-4a7f-8ada-f561f2ec5860" align="right" width="350" />

# KoalaVim

A meta-config for Neovim — a foundation you extend, not a finished config you adopt.

KoalaVim ships keymaps, autocmds, a curated plugin set, and a robust set of defaults. Your own config layers on top: add plugins, override anything, ship your taste. Pair it with [`kv`](https://github.com/KoalaVim/kv) for isolated environments, lockfile-pinned plugin sets, dependency installation, and git-aware launch modes — all driven from the terminal.

Powered by [lazy.nvim](https://github.com/folke/lazy.nvim).

<br><br><br><br><br><br>

---

## 🚧 KoalaVim is in early alpha. Expect breaking changes. 🚧

## Features

- **AI agents in your editor** — Claude / Codex / Cursor / opencode CLIs running inside nvim via [sidekick.nvim](https://github.com/folke/sidekick.nvim), plus KoalaVim's edit-prompt buffer, prompt navigation, and fast-typing auto-edit detection on top. Launch straight into AI mode with `kv --ai`.
- **Git-aware launch modes** — drop nvim straight into git workflows from the shell: `kv -g` (git mode), `kv -t` (tree), `kv --git-diff` (diff).
- **[Hydra](docs/plugins/hydra.md) sub-modes** — chord-style interfaces for repetitive sequences (window resize, diff viewing, …) without holding modifier keys.
- **A 16-category plugin map** — every choice documented at [`docs/plugins/`](docs/plugins/README.md), so you can see (and replace) what's in your editor.

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

- Enable the pre-commit hook:

  ```bash
  git config --local include.path ../.gitconfig
  ```

- Lua formatting via [`stylua`](https://github.com/JohnnyMorganz/StyLua) (config: [`stylua.toml`](stylua.toml)).
- Local development: create a scratch env pointing at your local KoalaVim checkout, e.g. `kv env create dev --from <path>`, or fork an existing env. See [kv env docs](https://github.com/KoalaVim/kv/blob/main/docs/envs.md).

## License

Licensed under [GPL-3.0](LICENSE).
