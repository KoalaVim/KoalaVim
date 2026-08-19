# AI

AI coding assistant integrations.

| Plugin | Description |
| --- | --- |
| [sidekick.nvim](https://github.com/folke/sidekick.nvim) | AI CLI sidecar (Claude, Copilot, Cursor, etc.) inside Neovim with NES inline next-edit suggestions and prompt send helpers. |

## EDITOR proxy

Sidecar-spawned CLIs receive `EDITOR` and `VISUAL` pointing at `bin/sidekick-editor-proxy`. This means the CLI's native edit-in-editor keybind (Ctrl+X for cursor/codex, Ctrl+X Ctrl+E for claude) opens the prompt in the running Neovim instance rather than spawning a nested editor. The file opens in a below-split; saving and closing the split returns the edited text to the CLI.

`<C-e>` remains the KoalaVim parse-and-inject prompt overlay and is unchanged by this feature.
