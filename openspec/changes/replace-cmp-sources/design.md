## Context

KoalaVim's autocompletion uses nvim-cmp with several source plugins. Three sources have known limitations:
- `cmp-look` depends on `/usr/share/dict/words` (Linux-only)
- `cmp-buffer` and `cmp-path` use exact prefix matching, no fuzzy capabilities

The `all_visible_buffers_source()` helper configures buffer completion across visible windows — this pattern must be preserved with the fuzzy replacement. The cmdline `/` search source also uses buffer completion.

## Goals / Non-Goals

**Goals:**
- Replace buffer/path/dictionary sources with fuzzy-capable alternatives
- Ensure cross-platform dictionary completion (macOS + Linux)
- Add @-triggered file mention completion via filemention.nvim
- Maintain existing priority ordering and integration with other sources

**Non-Goals:**
- Changing the completion engine (nvim-cmp stays)
- Modifying LSP, snippet, or cmdline completion behavior
- Changing keybindings or sorting comparators
- Configuring dictionary content (use plugin defaults initially)

## Decisions

### Use cmp-fuzzy-buffer + cmp-fuzzy-path from tzachar

Both plugins share a common dependency (`fuzzy.nvim`) and offer native fzf/fzy-based fuzzy matching. This is preferable over alternatives like `cmp-buffer` with custom filter functions because fuzzy scoring happens natively.

**Alternative considered:** Keep `cmp-buffer` and add `fzf-native` scoring externally — rejected because `cmp-fuzzy-buffer` handles this out of the box and integrates cleanly.

### Use cmp-dictionary from uga-rosa

Provides dictionary completion without system dependencies. Supports custom dictionary files and async loading. Works on all platforms.

**Alternative considered:** Ship a bundled word list with the plugin — rejected because `cmp-dictionary` already solves this with configurable paths and async loading.

### Add filemention.nvim as a standalone plugin entry

`filemention.nvim` provides @-triggered file path insertion. It's an independent plugin (not a cmp source), so it gets its own `table.insert(M, ...)` entry rather than being added to nvim-cmp's dependencies.

### Preserve visible-buffers pattern for fuzzy-buffer

The current `all_visible_buffers_source()` helper scopes buffer completion to visible windows. `cmp-fuzzy-buffer` supports a `get_bufnrs` option similarly — the helper function will be adapted.

## Risks / Trade-offs

- **[fzf/fzy binary required]** → `fuzzy.nvim` needs either `fzf` or `fzy` installed. Most developer machines have `fzf`. Document this as a dependency.
- **[Source name changes]** → `cmp-fuzzy-buffer` uses source name `fuzzy_buffer`, `cmp-fuzzy-path` uses `fuzzy_path`, `cmp-dictionary` uses `dictionary`. All source references in nvim-cmp config must update.
- **[cmdline `/` search source]** → Currently uses `cmp-buffer` via `all_visible_buffers_source()`. Needs migration to `cmp-fuzzy-buffer` equivalent for the cmdline context.
- **[Dictionary file setup]** → `cmp-dictionary` needs a dictionary file path configured. On first use without setup, dictionary completions won't appear. Mitigated by providing reasonable defaults in config.
