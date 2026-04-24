# Redundant plugin candidates

KoalaVim was originally assembled before AI coding agents (Claude Code, Copilot, Cursor, sidekick.nvim) became part of daily workflow.
Several plugins here solve problems that an AI agent now solves faster and more flexibly, or that a native Neovim feature covers out of the box.

The list below is a **shortlist for review**, not a removal plan. Each entry explains why it may no longer pull its weight.

All plugins still listed here have been reviewed and **decided kept** — they remain in the config on purpose. The rationale is left for future re-evaluation if priorities change.

## Tier 1 — strong candidates for removal

| Plugin | Category | Rationale | Decision |
| --- | --- | --- | --- |
| [nvim-toggler](https://github.com/nguyenvukhang/nvim-toggler) | Coding | Toggling `true↔false`, `prev↔next`, etc., is trivial prompt-work for an AI agent and works for any custom pair. | Kept |
| [muren.nvim](https://github.com/AckslD/muren.nvim) | Editor | Multi-pattern replace with preview is better covered by `nvim-spectre` + AI-authored sed/rg commands. | Kept |
| [nerdy.nvim](https://github.com/2kabhishek/nerdy.nvim) | Editor | Finding a Nerd Font glyph by name is a textbook AI ask and returns the exact character. | Kept |
| [ai.vim](https://github.com/aduros/ai.vim) (if present) | AI | Early GPT-3 plugin — fully superseded by `sidekick.nvim`. | Kept |
| [ChatGPT.nvim](https://github.com/jackMort/ChatGPT.nvim) (if present) | AI | Pre-agent chat UI — superseded by `sidekick.nvim` CLI agents. | Kept |
| [cmp-look](https://github.com/octaltree/cmp-look) | Autocomplete | Dictionary completion via `look(1)` is low-signal noise compared to AI NES/completions. | Kept |
| [cmp-calc](https://github.com/hrsh7th/cmp-calc) | Autocomplete | Tiny calculator source — trivially handled by AI or `:=`. | Kept |
| [cmp-git](https://github.com/petertriho/cmp-git) | Autocomplete | AI agents draft issue/PR references and commit messages better; commit hooks cover prefixes. | Kept |
| [telescope-dict.nvim](https://code.sitosis.com/rudism/telescope-dict.nvim) | Telescope | Synonyms and spell suggestions are first-class AI tasks. | Kept |

## Tier 2 — candidates worth reconsidering

| Plugin | Category | Rationale | Decision |
| --- | --- | --- | --- |
| [hex.nvim](https://github.com/RaafatTurki/hex.nvim) | Editor | Rarely used; `:%!xxd` handles the same job. | Kept |
| [nvim-snippy](https://github.com/dcampos/nvim-snippy) + [vim-snippets](https://github.com/honza/vim-snippets) | Autocomplete | Static snippet libraries overlap heavily with AI NES/inline completions. | Kept |
| [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | LSP/Markdown | Overlaps with `render-markdown.nvim` and `peek.nvim`; all three for one task is excessive. | Kept |
| [peek.nvim](https://github.com/toppair/peek.nvim) | LSP/Markdown | Already `enabled = false`; pick one markdown preview. | Kept |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | Games | Only relevant during onboarding; can stay, but not required. | Kept |

## Deferred / keep

Plugins that at first glance look duplicated by AI but actually still carry their weight:

- **sidekick.nvim** (ai.lua) — primary AI integration, keep.
- **nvim-cmp + cmp-nvim-lsp + cmp-buffer + cmp-path + cmp-cmdline** — still the core completion engine; only the *long-tail* sources (look, calc, git) are redundant.
- **gitsigns / fugitive / neogit / diffview / codediff / vim-flog / octo / git-messenger** — git UX plugins that operate on concrete repo state; AI doesn't replace interactive staging, blame, or PR review.
- **telescope + fzf-native + live-grep-args** — primary navigation; AI complements but does not replace fuzzy finding.
- **nvim-dap / nvim-dap-ui / nvim-dap-virtual-text / goto-breakpoints** — interactive debugging state cannot be prompt-driven.
- **treesitter + textobjects + context + matchup** — structural editing foundation.
- **leap / flit / mini.ai / nvim-surround / substitute / yanky / move.nvim / various-textobjs / visual-multi** — low-level editing ergonomics that are faster than prompting.
