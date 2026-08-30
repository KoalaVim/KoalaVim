## Why

The current completion sources (`cmp-look`, `cmp-buffer`, `cmp-path`) have limitations: `cmp-look` relies on `/usr/share/dict/words` which doesn't exist on non-Linux systems, `cmp-buffer` and `cmp-path` use basic matching without fuzzy capabilities. Replacing them with fuzzy-capable alternatives and adding file-mention support improves completion quality across platforms.

## What Changes

- Replace `octaltree/cmp-look` with `uga-rosa/cmp-dictionary` for cross-platform dictionary completions
- Replace `hrsh7th/cmp-buffer` with `tzachar/cmp-fuzzy-buffer` for fuzzy buffer word matching
- Replace `hrsh7th/cmp-path` with `tzachar/cmp-fuzzy-path` for fuzzy path completion
- Add `not-manu/filemention.nvim` for @-triggered file mention completions

## Capabilities

### New Capabilities

- `file-mentions`: @-triggered file path insertion via filemention.nvim

### Modified Capabilities

- `autocompletion`: Buffer, path, and dictionary sources are replaced with fuzzy/cross-platform alternatives. Source names and configuration options change.

## Impact

- `lua/KoalaVim/plugins/autocomplete.lua` — plugin specs, dependencies, and source configuration
- Plugin dependencies change (removed: cmp-look, cmp-buffer, cmp-path; added: cmp-dictionary, cmp-fuzzy-buffer, cmp-fuzzy-path, filemention.nvim)
- `cmp-fuzzy-buffer` and `cmp-fuzzy-path` depend on `fuzzy.nvim` (which requires either fzf or fzy binary)
- Dictionary source will need a dictionary file configured rather than relying on system `/usr/share/dict/words`
