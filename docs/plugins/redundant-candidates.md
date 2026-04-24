# Redundant plugin candidates

KoalaVim was originally assembled before AI coding agents (Claude Code, Copilot, Cursor, sidekick.nvim) became part of daily workflow.
Several plugins here solve problems that an AI agent now solves faster and more flexibly, or that a native Neovim feature covers out of the box.

The list below is a **shortlist for review**, not a removal plan. Each entry explains why it may no longer pull its weight.

## Tier 1 — strong candidates for removal

| Plugin | Category | Rationale |
| --- | --- | --- |
| [debugprint.nvim](https://github.com/andrewferrier/debugprint.nvim) | Coding | "Insert a language-specific debug print" is a one-shot task an AI agent handles in any language/style; the plugin only knows a fixed set of templates. |
| [nvim-toggler](https://github.com/nguyenvukhang/nvim-toggler) | Coding | Toggling `true↔false`, `prev↔next`, etc., is trivial prompt-work for an AI agent and works for any custom pair. |
| [text-case.nvim](https://github.com/johmsalas/text-case.nvim) | Coding | Case-conversion is a canonical single-selection AI ask; the plugin is a static cmd table. |
| [based.nvim](https://github.com/trmckay/based.nvim) | Editor | Hex ↔ decimal conversion is a calc/AI one-liner. |
| [muren.nvim](https://github.com/AckslD/muren.nvim) | Editor | Multi-pattern replace with preview is better covered by `nvim-spectre` + AI-authored sed/rg commands. |
| [color-picker.nvim](https://github.com/ziontee113/color-picker.nvim) | Editor | Rarely used in dev workflows; AI can generate color values from descriptions instantly. |
| [nerdy.nvim](https://github.com/2kabhishek/nerdy.nvim) | Editor | Finding a Nerd Font glyph by name is a textbook AI ask and returns the exact character. |
| [ai.vim](https://github.com/aduros/ai.vim) (if present) | AI | Early GPT-3 plugin — fully superseded by `sidekick.nvim`. |
| [ChatGPT.nvim](https://github.com/jackMort/ChatGPT.nvim) (if present) | AI | Pre-agent chat UI — superseded by `sidekick.nvim` CLI agents. |
| [cmp-look](https://github.com/octaltree/cmp-look) | Autocomplete | Dictionary completion via `look(1)` is low-signal noise compared to AI NES/completions. |
| [cmp-calc](https://github.com/hrsh7th/cmp-calc) | Autocomplete | Tiny calculator source — trivially handled by AI or `:=`. |
| [cmp-git](https://github.com/petertriho/cmp-git) | Autocomplete | AI agents draft issue/PR references and commit messages better; commit hooks cover prefixes. |
| [telescope-dict.nvim](https://code.sitosis.com/rudism/telescope-dict.nvim) | Telescope | Synonyms and spell suggestions are first-class AI tasks. |
| [commit-prefix.nvim](https://github.com/ofirgall/commit-prefix.nvim) | Git | Already disabled in favor of git `commit-msg` hooks — safe to drop. |

## Tier 2 — candidates worth reconsidering

| Plugin | Category | Rationale |
| --- | --- | --- |
| [nvim-peekup](https://github.com/gennaro-tedesco/nvim-peekup) | Editor | Native `:registers` / `""` in insert mode already show the same info; yank history lives in `yanky.nvim`. |
| [hex.nvim](https://github.com/RaafatTurki/hex.nvim) | Editor | Rarely used; `:%!xxd` handles the same job. |
| [iswap.nvim](https://github.com/mizlan/iswap.nvim) | Editor | Overlaps with `sibling-swap.nvim` (treesitter-based) and AI-driven edits. |
| [iron.nvim](https://github.com/Vigemus/iron.nvim) | Editor | REPL integration is often replaced by `:terminal` + AI-run snippets or Jupyter-compatible alternatives. |
| [nvim-puppeteer](https://github.com/chrisgrieser/nvim-puppeteer) | Editor | Auto-converting f-strings / template literals is a micro-optimization an AI agent covers implicitly. |
| [nvim-snippy](https://github.com/dcampos/nvim-snippy) + [vim-snippets](https://github.com/honza/vim-snippets) | Autocomplete | Static snippet libraries overlap heavily with AI NES/inline completions. |
| [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | LSP/Markdown | Overlaps with `render-markdown.nvim` and `peek.nvim`; all three for one task is excessive. |
| [peek.nvim](https://github.com/toppair/peek.nvim) | LSP/Markdown | Already `enabled = false`; pick one markdown preview. |
| [plantuml-previewer.vim](https://github.com/weirongxu/plantuml-previewer.vim) | LSP/PlantUML | AI generates/modifies PlantUML source; external viewers (VSCode/online) cover preview. |
| [vim-spellsync](https://github.com/micarmst/vim-spellsync) | Editor | Spell-file sync is easily replaced by keeping `spell/*.add` in a dotfiles repo. |
| [swap-split.nvim](https://github.com/riddlew/swap-split.nvim) | Editor | Niche; `wincmd x` handles the common case. |
| [nvim-peekup](https://github.com/gennaro-tedesco/nvim-peekup) | Editor | (listed above) |
| [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) | Games | Only relevant during onboarding; can stay, but not required. |

## Deferred / keep

Plugins that at first glance look duplicated by AI but actually still carry their weight:

- **sidekick.nvim** (ai.lua) — primary AI integration, keep.
- **nvim-cmp + cmp-nvim-lsp + cmp-buffer + cmp-path + cmp-cmdline** — still the core completion engine; only the *long-tail* sources (look, calc, git) are redundant.
- **gitsigns / fugitive / neogit / diffview / codediff / vim-flog / octo / git-messenger** — git UX plugins that operate on concrete repo state; AI doesn't replace interactive staging, blame, or PR review.
- **telescope + fzf-native + live-grep-args** — primary navigation; AI complements but does not replace fuzzy finding.
- **nvim-dap / nvim-dap-ui / nvim-dap-virtual-text / goto-breakpoints** — interactive debugging state cannot be prompt-driven.
- **treesitter + textobjects + context + matchup** — structural editing foundation.
- **leap / flit / mini.ai / nvim-surround / substitute / yanky / move.nvim / various-textobjs / visual-multi** — low-level editing ergonomics that are faster than prompting.

## Suggested next step

Pick Tier 1 plugins, disable them with `enabled = false` for one week, and remove any you don't miss. Tier 2 items are best revisited together with a review of the workflow they used to serve.
