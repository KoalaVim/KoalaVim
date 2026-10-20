## Context

LazyVim's `coding.nvim-cmp` extra defines `hrsh7th/nvim-cmp` with an `opts` function (registering cmp-nvim-lsp capabilities, its own mapping/sources/formatting) and `main = "lazyvim.util.cmp"`. lazy.nvim therefore calls `LazyVim.cmp.setup(opts)`, which:
- defaults each source's `group_index` to 1
- wraps cmp's snippet parser with a preview fallback
- calls `cmp.setup(opts)`
- adds a `confirm_done` auto-brackets hook for `opts.auto_brackets` filetypes
- adds missing snippet docs on `menu_opened`

A second spec in the extra adds nvim-snippets/friendly-snippets and sets `opts.snippet.expand = LazyVim.cmp.expand` (native `vim.snippet`).

KoalaVim's current `config` builds everything inline and also sets up cmdline/filetype configs and the autopairs hook.

## Goals / Non-Goals

**Goals:** Keep KoalaVim's completion behavior unchanged for users, run it on LazyVim's extra, and move snippets to the native engine.

**Non-Goals:** blink.cmp (decided against). Changing source behavior or fuzzy backends.

## Decisions

### D1. Opts function replaces, config wraps
KoalaVim's nvim-cmp spec provides `opts = function(_, opts)`, which runs after the extra's. It **replaces** `mapping`, `sources`, `sorting`, `formatting`, `window` and `preselect`, and sets `completion.completeopt = 'menu,menuone,noinsert,noselect'`. It keeps `snippet`, `auto_brackets` and `experimental.ghost_text` (AI) from LazyVim. A custom `config = function(_, opts)` calls `require('lazyvim.util.cmp').setup(opts)` and then performs KoalaVim's extra setup: `cmp.setup.cmdline('/')`, `cmp.setup.cmdline(':')`, filetype setups, lspkind-priority setup and the autopairs hook. `event = { 'InsertEnter', 'CmdlineEnter' }`.
*Alternative:* keep KoalaVim's own `config` and skip `lazyvim.util.cmp`. Rejected because it loses snippet preview/fix and the AI Tab chain.

### D2. Tab chain
```
<Tab>   : cmp.visible() → select_next_item
          else LazyVim.cmp.map({ 'snippet_forward', 'ai_nes', 'ai_accept' }, fallback)
<S-Tab> : cmp.visible() → select_prev_item
          elseif vim.snippet.active({ direction = -1 }) → vim.snippet.jump(-1)
          else fallback
<CR>    : confirm only if an entry is explicitly selected (KoalaVim behavior)
```
Modes `i` and `c`, as today. KoalaVim's doc-scroll keys (`<C-u>/<C-d>/<C-y>/<C-e>`) and `<C-Space>` stay. LazyVim's `<C-b>/<C-f>/<S-CR>/<C-CR>/<C-y>` cmp mappings are dropped because KoalaVim's mapping table replaces theirs.

### D3. Snippets: native + converted collections
- Drop nvim-snippy, cmp-snippy and vim-snippets. Their `s`/`nx` Tab mappings are replaced by D2.
- Convert KoalaVim's `snippets/*.snippets` to `snippets/<lang>.json` with a `snippets/package.json` (VSCode contributes format). Add KoalaVim's `snippets/` directory to nvim-snippets `search_paths`.
- From `ofirgall/vim-snippets`, convert only the snippets that differ from honza/vim-snippets upstream (`git diff` of the fork against its upstream base). friendly-snippets covers most of the generic honza content.
- Snipmate interpolation (backticks / `${VISUAL}`) has no VSCode equivalent. Rewrite those cases as plain placeholders, or use `$TM_SELECTED_TEXT` where it applies.
- Source name changes from `snippy` to `snippets` and keeps priority 200.

### D4. Autopairs vs auto_brackets
LazyVim's language extras add filetypes to `opts.auto_brackets` (python). nvim-autopairs' `on_confirm_done` also inserts `(`. Keep nvim-autopairs as the only bracket inserter by clearing `opts.auto_brackets` in KoalaVim's opts function.

### D5. Capabilities
The extra registers `cmp_nvim_lsp.default_capabilities()` via `vim.lsp.config("*")`. KoalaVim's `labelDetailsSupport = nil` tweak is applied through `servers["*"].capabilities` on lspconfig. Merge order: lspconfig `servers["*"]` is applied at lspconfig config time, after the cmp opts function. Verify the final value with `:lua =vim.lsp.config["*"]`.

## Implementation notes (as built)

- **D1:** KoalaVim's `opts` function returns `vim.tbl_extend('force', opts, {...})`. That replaces `mapping`, `sources`, `sorting`, `formatting`, `window`, `preselect` and `experimental`, and sets `completion.completeopt` and `auto_brackets = {}`. `snippet` is kept from the extra. `experimental.ghost_text` stays `false`, as KoalaVim had it. LazyVim's `vim.g.ai_cmp` default would otherwise show ghost text for ordinary items, because KoalaVim has no AI cmp source.
- **D3, snippets:**
  - KoalaVim's snippets are `snippets/{c,go,lua,python,rust,yaml}.json` plus `snippets/package.json`. `c.json` serves both `c` and `cpp`.
  - They're added to nvim-snippets `search_paths`, next to the user's `<config>/snippets`.
  - From the `ofirgall/vim-snippets` fork, only KoalaVim's own commits were converted:
    - C brace-on-new-line `if`/`ife`/`el`/`elif`/`switch`/`for`/`wh`
    - Go `fori`/`forr`
    - Rust `useserde`/`serdestruct`/`typeresult` (snipmate's `use serde` trigger becomes the prefix `useserde`)
    - YAML `githubaction`
  - Global and codeblock removals need no conversion.
- **Native engine limits:**
  - `vim.snippet` doesn't parse a variable inside a placeholder default (`${1:${TM_FILENAME_BASE}}`).
  - It ignores `/upcase` transforms.
  - So `headerguard` and `clas` use bare `${TM_FILENAME_BASE}`. The guard keeps the filename's own case (`my_header_H_` rather than `MY_HEADER_H_`), and the class name is no longer a placeholder.
  - `${VISUAL}` defaults became plain placeholders.
- **D5:** `labelDetailsSupport = false` is set in lspconfig `servers["*"].capabilities` and merges over cmp_nvim_lsp's capabilities. At runtime, `vim.lsp.config["*"]` shows `snippetSupport = true` and `labelDetailsSupport = false`.

## Risks / Trade-offs

- [Some snipmate snippets don't convert cleanly (interpolation, `${VISUAL}`)] → Manual rewrite; list the affected snippets in the tasks.
- [Users lose the honza collection beyond what friendly-snippets covers] → Accepted. Users can add a snippets path.
- [`LazyVim.cmp.setup` sets `group_index = 1` on sources without one, changing KoalaVim's grouping (lazydev uses group 0)] → KoalaVim already sets lazydev's group 0 explicitly; all other sources share group 1, the same as today.
- [The AI `ai_accept`/`ai_nes` actions only exist if an AI extra registers them] → `LazyVim.cmp.map` skips missing actions, so the chain degrades to fallback.

## Open Questions

- Should KoalaVim register sidekick NES as `LazyVim.cmp.actions.ai_nes`, so Tab accepts next-edit suggestions? Would be nice, but out of scope here.
