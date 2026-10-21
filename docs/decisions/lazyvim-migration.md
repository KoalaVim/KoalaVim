# KoalaVim over LazyVim — decision log

Goal: KoalaVim becomes a meta-config on top of LazyVim. We use LazyVim's framework
(loader, `LazyVim.*` utils, extras, opts-merging, keymap/toggle system) and its
preconfigured plugins where they're stronger, and keep KoalaVim's own versions
where KoalaVim is more mature.

Snapshot: LazyVim 16.0.1 (`~/workspace/personal/LazyVim`, upstream main),
KoalaVim `over-lazyvim` @ 9d2c446.

**Status (2026-10-21):** implemented on the `over-lazyvim` branch through five OpenSpec changes:
`lazyvim-foundation`, `lazyvim-lsp-formatting`, `lazyvim-completion`, `lazyvim-ui-editing`, `flavor-keymaps`.
D1–D47 and the tables below are the planning-time decisions. D48+ were decided during implementation.
Where an earlier entry was superseded, the newer entry says so.

Where the decisions live in the code and docs:
- Keymaps per flavor: `lua/KoalaVim/keymaps/contested.lua` (data), `docs/keymaps.md` (generated cheat sheet,
  `make gen-keymaps-doc`), `make test-keymaps` (checks both flavors).
- Flavor: `lua/KoalaVim/flavor.lua` (`flavor` in kvim.conf, default `koala`).
- Rationale per area: the `design.md` of each change under `openspec/changes/` (or `openspec/changes/archive/`
  once archived), especially the "Implementation notes (as built)" and "Resolved Questions" sections.

---

## Target shape (working draft)

```
 user config (KoalaConfig.template / kv env)
   └─ lazy.setup({ spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },   ← 1. LazyVim core
        { import = "lazyvim.plugins.extras.…" },             ← 2. extras Koala picks
        { "KoalaVim/KoalaVim", import = "KoalaVim.plugins" }, ← 3. Koala overrides/additions
        { import = "plugins" },                               ← 4. user
      }})
```

Koala layer per plugin is one of:
- **take**   — LazyVim's spec as-is, maybe small `opts` tweaks
- **keep**   — Koala's plugin; disable LazyVim's equivalent (`enabled = false`)
- **fuse**   — LazyVim's plugin + mechanism, Koala features layered in via `opts`/hooks

---

## Decided

| # | Area | Decision | Notes |
|---|------|----------|-------|
| D1 | which-key | **take** LazyVim | Koala's which-key config is effectively empty (commented-out groups). |
| D2 | Completion | **Koala features** | Engine not decided yet — see Q3. Must keep: fuzzy buffer (visible wins), fuzzy path, fuzzy dictionary, agents-skills, filemention, calc, cmp-git, crates, lspkind priority sort, kw/text cword filter, Tab/S-Tab + snippet jumps, `<CR>` only confirms explicit selection, cmdline `/` + `:` sources. |
| D3 | Theme | **ofirkai** | Set `LazyVim.config.colorscheme`. ofirkai has hl groups for cmp/noice/snacks/telescope/trouble/nvim-tree/lazy/flash; **none for blink, which-key, mini.\***. |
| D4 | Integration model | **Spec layer** | `lazyvim.plugins` → chosen extras → `KoalaVim.plugins` → user `plugins`. LazyVim stays a pinned upstream dependency, not a fork. |
| D5 | Completion engine | **nvim-cmp** via LazyVim's `coding.nvim-cmp` extra (`vim.g.lazyvim_cmp = "nvim-cmp"`) | Koala is a **fuse** layer: keep LazyVim's `main = "lazyvim.util.cmp"` (auto_brackets, `LazyVim.cmp.map` snippet/AI Tab chain), override `sources`/`sorting`/`mapping`/`formatting`/`window` through an `opts` function. Koala's cmdline/filetype setups go in a separate `config` hook. ofirkai already covers cmp hl. |
| D6 | Formatting | **LazyVim format-on-save** | Drop format-on-leave. Gives us `LazyVim.format`, `<leader>uf/uF`, `vim.g/b.autoformat`, and conform's `config` stays LazyVim's `M.setup`. Per-language formatters come from conform `formatters_by_ft` opts and lang extras instead of the `CONFORM_FORMATTERS` global. |
| D7 | Keymap configurability | **Follows `flavor`** (see D18); default `koala` | Applies only to the **contested keys** (one conflict table). Prerequisite: `kvim.conf` must load *before* spec resolution (move `conf.load()` out of the KoalaVim plugin `config` hook). *(Revised from `keymaps.preset`; replaced by D18.)* |
| D8 | AutoSave × format-on-save | **AutoSave writes skip formatting** | AutoSave's write path turns autoformat off for that write only (flag/`noautocmd`-style guard around LazyVim's BufWritePre). Formatting happens only on explicit `:w` / `<leader>cf`. |
| D9 | kvim.conf format knobs | **Map onto LazyVim** | `*.blacklist_ft` → FileType autocmd sets `vim.b.autoformat = false` (autoformat) / blocks format entirely (format). `*.blacklist` (LSP clients) → filter in `LazyVim.lsp.formatter` (via `opts.servers[x]` / custom filter). After D8, `autoformat.*` applies only to explicit `:w`. |
| D10 | Snippets | **LazyVim native** (nvim-snippets + friendly-snippets + `vim.snippet`) | Drop nvim-snippy/cmp-snippy. **Convert** KoalaVim's `snippets/{c,go,lua,python}.snippets` (snipmate) and the Koala-specific additions in the `ofirgall/vim-snippets` fork (diff vs honza upstream) to VSCode JSON, loaded as an extra `search_paths` entry. |
| D11 | LSP server definitions | **LazyVim lang extras + Koala per-server deltas** | Enable extras: clangd, cmake, docker, go, json, markdown, python, rust, typescript, zig (+ bash/vimls via plain `opts.servers`). Koala server files become `opts.servers[x]` overrides. `kvim.conf lsp.tsgo.enabled` → `vim.g.lazyvim_ts_lsp = "tsc"`; `lsp.vtsls.max_memory` → vtsls settings override. Remove `LSP_SERVERS`/`LSP_SERVER`/`LSP_CAPS`/`LSP_ON_*`/`LOADED_LSP_SERVERS` globals (`dont_format` → D9 client filter). Python: ruff_lsp → ruff (LazyVim). Open: go.nvim vs plain go extra. |
| D12 | Linting | **nvim-lint** | Drop none-ls and `NONE_LS_SRCS`. mypy → `linters_by_ft.python` + wrapped parser that keeps Koala's postprocess (import-not-found/import-untyped → INFO with a friendly message) and `--check-untyped-defs`. Lint on save, matching `DIAGNOSTICS_ON_SAVE`. |
| D13 | Diagnostics display | **Koala 3-mode cycle, native backend** | Base = LazyVim `opts.diagnostics` (+ Koala signs/icons, underline off, update_in_insert off). Modes: diagflow / native `virtual_lines` / errors-only `virtual_text`. Drop the lsp_lines plugin. `<leader>l` cycles (koala preset; contested with LazyVim `<leader>l` = Lazy). |
| D14 | LSP UI | **keep** illuminate, inlay-hints EOL fork, semantic tokens OFF; **drop** lspsaga | illuminate → LazyVim `editor.illuminate` extra (turns off Snacks.words) + Koala opts and `<C-n>/<C-p>` + dr-lsp counter. Inlay hints: set LazyVim `opts.inlay_hints.enabled = false` so it doesn't fight the fork; `<leader>T` toggle (koala preset) vs `<leader>uh`. Semantic tokens: `servers["*"].on_init` strips `semanticTokensProvider` (also makes LazyVim's gopls semanticTokens workaround moot). lspsaga gone: `<F2>` → `vim.lsp.buf.rename`, `<F4>` → `vim.lsp.buf.code_action`, `<leader>L` → `vim.diagnostic.open_float` (koala preset). **Lost: lightbulb sign** — accept or replace later. |
| D15 | Picker | **Fuse: fff + snacks** | fff handles find_files/live_grep (and Koala's `<leader>fm` grep operator); the snacks picker with Koala's layout handles the rest. Register a fff backend behind `LazyVim.pick` so LazyVim's picker keys and lang-extra calls (`LazyVim.pick("files")`, `("live_grep")`, `{root=false}`, `cwd=`) land in fff, falling back to snacks for anything fff doesn't do. |
| D16 | Explorer | **nvim-tree (Koala)** | Turn off `editor.snacks_explorer` (`vim.g.lazyvim_explorer`, or disable the default extra) and keep Koala's node actions. |
| D17 | Motion | **leap + flit (Koala)** | Turn off flash (`folke/flash.nvim`, `enabled = false`). Lost from LazyVim: flash `<c-space>` TS incremental selection (Koala already has `<CR>`/`<BS>`), flash `r`/`R` remote ops, flash-in-picker jump. |
| D18 | Preset model | **One global `flavor: "koala" \| "lazyvim"`** (default `koala`), no per-area mixing | Read before lazy processes the plugin list. Areas that follow it: keymaps (D7), statusline/bufferline, dashboard, sessions, terminal. Specs switch with `enabled = function() return flavor == … end` / `cond`, or with flavor-selected `opts`/`keys`. |
| D19 | Statusline & bufferline | **Flavor-driven** | koala → Koala's lualine/bufferline (ofirkai statusline/tabline + Koala components). lazyvim → LazyVim's lualine/bufferline with the ofirkai theme. |
| D20 | Dashboard | **Flavor-driven** | koala → alpha fork. lazyvim → snacks.dashboard. Koala hooks that assume alpha (`CLOSE_KOALA_DASHBOARD`, `AlphaClosed`, kv modes) need a flavor-neutral event. |
| D21 | Sessions & terminal | **Flavor-driven** | koala → possession + toggleterm/term-edit. lazyvim → persistence + snacks.terminal. ⚠ The two session stores are separate, so changing flavor doesn't carry sessions over. The cwd-session logic and kv modes (`utils/session.lua`, `restore.lua`) need a small session adapter. |
| D22 | Autopairs | **nvim-autopairs (Koala)** | Turn off `nvim-mini/mini.pairs`. Keep the cmp `confirm_done` hook (works with the D5 nvim-cmp). |
| D23 | Comments | **Comment.nvim (Koala)** | Turn off `folke/ts-comments.nvim`. Keep ts-context-commentstring. Check that Comment.nvim's mappings override nvim's built-in `gc`/`gcc`. |
| D24 | Surround | **nvim-surround (Koala)** | Don't enable the mini.surround extra. LazyVim's which-key `gs = surround` group label comes out of the Koala which-key spec. |
| D25 | Search & replace | **spectre + muren (Koala)** | Turn off `MagicDuck/grug-far.nvim`. LazyVim's `<leader>sr` goes to spectre under the koala flavor. |
| D26 | Trouble | **trouble v3 (LazyVim)** | Drop the `ofirgall/trouble.nvim` v2 fork. Port: `hydras/helpers/trouble.lua` (v2 API), Koala's `<leader>t` toggle, the fork's `TroubleCursorLine` hl (check ofirkai's Trouble groups against v3 names). |
| D27 | Noice / progress | **Fuse noice, keep fidget** | LazyVim's noice opts + Koala's `misc/noice_routes.lua`. Set noice `lsp.progress.enabled = false` so fidget shows LSP progress. Keep Koala's `cmdheight=0` expectations. |
| D28 | Snacks UI modules | **Koala plugins** | Keep indent-blankline, statuscol.nvim, dressing. Turn off snacks `indent`, `scope`, `statuscolumn`, `input`. (`picker.ui_select` stays on per Koala.) Still to check: snacks `scroll`, `words` (off due to D14 illuminate), `bigfile`, `quickfile`. |
| D29 | DAP | **Fuse** | Enable `dap.core` extra (+ lang extras' debugger hooks). Layer Koala's dap-ui layout, nvim-dap-virtual-text opts, goto-breakpoints, format-on-leave dep removal (D6). Koala DAP keys vs LazyVim `<leader>d*` → contested-keys table (D7). Mason `debugpy` comes from the python extra. |
| D30 | Textobjects (mini.ai) | **LazyVim's mini.ai** *(recommended, not explicitly confirmed)* | Koala's spec is a bare setup on the old `echasnovski/mini.ai` repo name. Take LazyVim's (nvim-mini/mini.ai + custom objects + which-key labels). Keep various-textobjs + TS textobjects. Watch for clashes between mini.ai objects (`o f c t d e g u U`) and various-textobjs keys. |
| D31 | Options / keymaps / autocmds base | **LazyVim base + Koala on top** | Load order: `lazyvim.config.<x>` → Koala `config/<x>` (on the `User LazyVim{Options,Keymaps,Autocmds}Defaults` events) → user `config.<x>`. The Options listener has to be registered **before** `lazyvim.plugins` is imported (options load at spec time), so it goes in the KoalaVim bootstrap/`init()`. Koala's `config_lazy/*` stays on the lazy.nvim `LazyVimStarted` event. Replace `require_dir`'s `fd`/`ls` popen scan with `vim.fs.dir` (side cleanup). |
| D32 | Git | **Fuse gitsigns, Koala git UI** | LazyVim's gitsigns opts + `<leader>gh*`/`]h` keys as the base; Koala's gitsigns config/keys on top, contested keys per flavor. Keep neogit fork, fugitive, codediff fork, flog, git-messenger, octo, inlinediff, gitlinker, git-blame. Snacks lazygit (`<leader>gg`) stays available. |
| D33 | Go | **LazyVim go extra + go.nvim commands only** | The go extra owns gopls/gofumpt/goimports/dap-go. go.nvim set to `lsp_cfg = false`, no formatter/linter hooks; kept for its commands. |
| D34 | Symbol navigation | **Keep all Koala** | navic attach moves from the removed `LSP_ON_ATTACH` (D11) to `Snacks.util.lsp.on({method="textDocument/documentSymbol"})` or `servers["*"].on_attach`. navbuddy `<M-n>`, dr-lsp counter unchanged. Don't enable LazyVim's `editor.navic` extra. |
| D35 | Treesitter | **LazyVim spec + Koala extras** | LazyVim's nvim-treesitter (main) spec and `LazyVim.treesitter` install/fold/indent. Koala adds endwise, matchup, jsonpath, `vim.treesitter.language.register('markdown','sidekick_koala_prompt')`, its textobject keys, and treesitter-context (Koala spec, D36). Koala's `<CR>`/`<BS>` "increment selection" keys are **desc-only stubs** today (main dropped the incremental_selection module), so they need a real node-select helper. Check Koala's per-buffer fold/indent logic against LazyVim's `folds`/`indent` features. |
| D36 | Koala plugins that have LazyVim extras | **Keep Koala's specs** | Don't enable `coding.yanky`, `ui.smear-cursor`, `editor.mini-move`, `editor.dial`, `ui.treesitter-context`. Avoids yanky's `<leader>p`/`[p`/`]p` and dial's `<C-a>/<C-x>` clashes. treesitter-context may borrow LazyVim's `<leader>ut` Snacks toggle. |
| D37 | Snacks misc modules | **All on**: bigfile, quickfile, scroll, notifier | Watch: snacks `scroll` vs scrollofffraction, smear-cursor, and Koala's `nzz`/`<C-o>zz`/`<C-i>zz` recentering (animated recenter on every jump). notifier coexists with noice (LazyVim hands `vim.notify` back to noice). Revisit if scroll feels off. |
| D38 | Lightbulb | **Accept the loss** | No code-action sign after dropping lspsaga. |
| D39 | Extras management | **Koala hard-codes its required extras + `:LazyExtras` for users** | `KoalaVim/spec.lua` imports `lazyvim.plugins.extras.{coding.nvim-cmp, dap.core, editor.illuminate, lang.*}` **before** `KoalaVim.plugins`. User-picked extras go to `lazyvim.json` in the kv env config (`lazyvim.plugins.xtras` imports them with `lazyvim.plugins`, so still ahead of Koala). `lazyvim_check_order` is fine: it only matches `^plugins$`. Watch: a user extra that turns on something Koala turned off (e.g. `editor.snacks_explorer`, `coding.blink`) — decide later whether Koala warns. |
| D40 | LazyVim pin | **Koala's lazy-lock.json** | LazyVim's commit pinned in the deterministic lockfile (`dev/gen_lockfile_init.lua`) like every other plugin; LazyVim bumps ship with Koala releases. |
| D41 | LazyVim news | **On** | Keep `news.lazyvim = true`. Note that some entries describe features Koala overrides. |
| D42 | ofirkai gaps | **Add to the ofirkai repo** | Add groups upstream in `ofirgall/ofirkai.nvim`: which-key, mini.icons/mini.ai, snacks dashboard (lazyvim flavor), trouble v3 names (+ the fork's `TroubleCursorLine`), plus anything the snacks modules from D37 add (notifier, scroll is n/a). |
| D43 | koala flavor: key-group clashes | **Koala keys win; LazyVim's groups move** | `<leader>c/d/s/b/<Tab>` keep Koala's meaning (`"_c`, `"_d`, spell hydra, build, `b#`). LazyVim's code/debug/search/buffer/tabs groups, **including lang-extra keys**, are remapped to free prefixes (see Q-K1). Needs a spec post-processor that rewrites `keys` of LazyVim specs + `servers[*].keys` + global keymaps by prefix. |
| D44 | lazyvim flavor: Koala-only keys | **Keep features, drop duplicates** | Keep Koala keys for things LazyVim lacks (AI, hydras, splits `<M-e/o/q/w>`, tabpages, `<leader>1..0`, os-clipboard `<leader>y/p`, surround `s*`, splitjoin, toggler, VM, sibling-swap, F-key debug?, etc.). Drop Koala keys that repeat a LazyVim action (`<leader>F`, `<leader>h*`, `<leader>T`, `]c`/`<M-j/k>` hunks, `<leader>up`, `gi`/`gt`, `<leader>L`, `<leader>qq`…). Koala features that lost their key in table A still need a home in this flavor. |
| D45 | koala flavor: LazyVim vim-default overrides (table C) | **Drop** | koala flavor keeps vim's own `H`/`L`, `<A-j/k>` (i/v), `<C-s>`, `<esc>`, insert `, . ;`, x `<`/`>`, `gco`/`gcO`, `[b ]b [B ]B`, `]] [[`, `gy`, `gK`, `<leader>-`/`<leader>|`. Simplest way: `defaults.keymaps = false` under koala and re-add only the LazyVim global keys Koala wants. |
| D46 | koala flavor: same-intent duplicates (table D) | **Koala's only** | LazyVim's duplicate bindings are removed under koala (`<leader>cf`, `]h`/`[h`, `<leader>gh*`, `<leader>uh`, `<leader>cr/ca/cd`, `gI`/`gy`, `<leader>gf`, `<c-/>`, `<leader>e`, dap.core keys that repeat F-keys: `db dc di dO do dC dr de`). |
| D47 | koala flavor: where LazyVim's groups move | code → **`<leader>v`**, debug → **`<leader>r`** (joins Koala's), search → **merged into `<leader>f`**, buffers → **`<leader>q`**, tabs → **dropped** | Full key-by-key map in the "koala flavor: relocation map" section. |
| D48 | lazyvim flavor: no-yank change/delete | **`<leader>C` / `<leader>D`** operators | KoalaVim's `"_C`/`"_D` line variants are dropped in the lazyvim flavor; use `<leader>C$` / `<leader>D$` instead. (2026-10-21) |
| D49 | lazyvim flavor: build & deploy | **`<leader>rb` / `<leader>rB`** | The `r` group is free in LazyVim's layout. (2026-10-21) |
| D50 | lazyvim flavor: spell hydra | **`<leader>uZ`** | First proposed as `<leader>uz`, but that's LazyVim's zen-mode toggle. (2026-10-21) |
| D51 | KoalaVim-internal: `<leader>fcd` vs `<leader>fcdw` | **`fcd` → `fcdd`** | `<leader>fcd` becomes a group (`fcdd` = find in current dir, `fcdw` = word in current dir); `fC*` in the lazyvim flavor. (2026-10-21) |
| D52 | KoalaVim-internal: `<C-.>` | **Split by mode, as at runtime** | Normal: bufferline next. Insert/terminal/visual: Sidekick toggle (Sidekick's spec drops `n`). (2026-10-21) |
| D53 | Keymap adjustments made during implementation | See `flavor-keymaps` design "as built" | koala: `<C-s>` is KoalaVim's (git status) in every mode; LazyVim's `[b ]b [B ]B` and illuminate's `]] [[` dropped (collide with treesitter motions); `<leader>xX` dropped (= `<leader>t`); dap `dt` dropped. lazyvim: KoalaVim's treesitter block jumps `]b [b ]B [B` → `]o [o ]O [O`; `fc*`/`fn*` → `fC*`/`fN*`; `<leader>e`/`<leader>E` open nvim-tree; `<C-w>` resizer hydra dropped (which-key's window popup wins). Both: checkmate `<leader>t*` and its `<leader>T*` metadata keys → `<localleader>`; c/cpp CRLF `<leader>n` → `<leader>vn` / `<leader>cn`; Go `<leader>fln` → `<leader>vp` / `<leader>cp`. |
| D54 | Keymap engine | **Data-driven remap + `check()`** | `contested.lua` + `remap` (lazy `keys` functions, LSP server keys, LazyVim globals, a re-sweep for keys LazyVim creates at runtime) + `kmap`/`kkeys`/`klhs` for KoalaVim's own keys. `check()` (also in `:checkhealth KoalaVim`) fails on ambiguous leader prefixes and on contested keys resolving to the wrong side. Supersedes the D7 "conflict table" sketch. |
| D55 | Which-key groups per flavor | **Generated from the flavor** | koala: `v` code, `r` run/debug, `f` find/search (+`fc`, `fcd`, `fN`), `q` quit/buffers, `z` lazy, `a` ai, `h` hunks, `uP` profiler; LazyVim's `c d s b <tab> w` groups removed. lazyvim: LazyVim's groups + `a`, `gO` octo, `r` run/build, `h`, `fC`/`fCd`, `fN` (spectre). |
| D56 | ofirkai pin | **Branch `feat/lazyvim`** | The colorscheme fix and the LazyVim plugin highlights live on ofirkai `feat/lazyvim`. KoalaVim's ofirkai spec has `branch = 'feat/lazyvim'` until it's merged to ofirkai master. |
| D57 | snacks.nvim | **Bumped to upstream main (`882c996`)** | The pinned LazyVim calls `Snacks.terminal.focus` and `Snacks.bufdelete.invisible`, which the old pin lacked. |
| D58 | Lockfile generator | **Covers every flavor** | `vim.g.koala_all_flavors` makes `flavor.is()` true for both flavors during generation. The generator also loads only `default_kvim.conf` and ignores the developer's `lazyvim.json`. |
| D59 | Default extras | **`vim.g.lazyvim_cmp = 'nvim-cmp'`** set in KoalaVim's options | LazyVim's options reset it, and blink's default extra would replace KoalaVim's nvim-cmp. Supersedes "D5 engine choice only". |
| D60 | trouble | **folke/trouble.nvim v3** | Supersedes the v2 fork; KoalaVim's trouble keys yield to LazyVim's v3 keys (`<leader>x*`); `<leader>t` = buffer diagnostics. |
| D61 | Snippets (native engine limits) | **Bare `${TM_FILENAME_BASE}`** | `vim.snippet` can't nest variables in placeholders or uppercase them, so `headerguard` gives `name_H_` and `clas` takes the filename. |
| D62 | DAP | **Close the dap-ui tab on session close too** | `disconnect` can drop `terminated`/`exited`. On macOS, compile C/C++/Rust through real paths: lldb won't resolve breakpoints for `/tmp`-symlinked builds. |

---

## Open questions

### ~~Q2 — Keymap layout~~ → D7

User asked whether it can be configurable. Analysis:
- It's feasible. Keys come from 4 places: `lazyvim.config.keymaps` (global, can be turned off with `defaults.keymaps`), plugin spec `keys`, `servers["*"].keys` (LSP, `has=` gated), and `gitsigns.on_attach`.
- **Blocker:** `kvim.conf` is loaded today in the KoalaVim plugin's `config` hook, which runs *after* lazy has resolved the specs. A setting that changes spec `keys` has to be readable while the spec loads. So `conf.load()` has to move earlier, e.g. the top of the first `KoalaVim.plugins` module or `KoalaVim.init()` before `lazy.setup`. That's the same pattern LazyVim uses with `vim.g.lazyvim_*`.
- Cheapest version: the preset only governs the **contested keys** (a conflict table, roughly 15–25 entries), not two full layouts.

### ~~Formatting consequences of D6~~ → D8, D9
- AutoSave (fork) saves on InsertLeave/TextChanged in normal mode. With format-on-save that means **a synchronous conform run on every normal-mode edit** (LazyVim sets `async = false`). format-on-leave was async. Slow formatters will lag the editor; this was the reason for `lsp.autoformat.blacklist`.
- kvim.conf `lsp.format.*` / `lsp.autoformat.*` blacklists: map them onto LazyVim (`vim.b.autoformat=false` via FileType autocmd for `blacklist_ft`; filter out LSP clients for `blacklist`), or drop them?

### Still open
None. Every open item was decided. See D48–D62 for decisions made during implementation.

---

## Contested keys (D7)

> Planning-time audit (2026-10-20). The implemented, up-to-date table is `lua/KoalaVim/keymaps/contested.lua`, and the generated cheat sheet is `docs/keymaps.md`. Rows marked `?` and the `<leader>uz` proposal are superseded by D48–D53.

Source: static scan of LazyVim's `config/keymaps.lua`, core plugin specs, the extras we enable (D39: snacks_picker, nvim-cmp, dap.core, illuminate, lang.*), the LSP `servers["*"].keys`, and gitsigns `on_attach`, compared with KoalaVim's `config/keymaps/*`, plugin `keys`, `map_buffer` calls, and hydra bodies. Keys from plugins we turned off (flash, grug-far, snacks explorer, mini.pairs, ts-comments, lspsaga) are left out.
`koala` / `lazyvim` columns are **proposals** until the policies below are settled. "→" means the losing action moves to that key.

### A. Hard collisions: same key, different action

| Key | Mode | LazyVim | KoalaVim | `koala` flavor | `lazyvim` flavor |
|---|---|---|---|---|---|
| `<leader>l` | n | Lazy | cycle diagnostics mode (D13) | K; Lazy → `<leader>zz` | L; cycle → `<leader>uv` |
| `<leader>L` | n | LazyVim changelog | line diagnostics float | K; changelog → `<leader>zl` | L; K's = L `<leader>cd` (drop) |
| `<leader>qq` | n | quit all | delete buffer | K; quit all → `<leader>qQ` | L; K's = L `<leader>bd` (drop) |
| `<leader>,` | n | buffers picker | prev tabpage | K; L's = `<leader>fb` (drop) | L; K's = `<leader><tab>[` (drop) |
| `<leader>.` | n | scratch buffer | next tabpage | K; scratch: drop (keep `<leader>S`) | L; K's = `<leader><tab>]` (drop) |
| `` <leader>` `` | n | other buffer | surround-replace to `` ` `` | K; L's = K `<leader><Tab>` (drop) | L; drop K's `` ` `` shortcut (`<leader>" ( [ {` stay) |
| `<leader>ud` | n | toggle diagnostics | toggle dim | **both: L**; K's dim = L `<leader>uD` |  |
| `<leader>fr` | n | recent files | resume picker | K; recent → `<leader>fR`¹ | L; K's = L `<leader>sR` (drop) |
| `<leader>gg` | n | lazygit (root) | diff-viewer hydra body | K; lazygit stays on `<leader>gG` | L; hydra → `<leader>gV` |
| `<leader>gs` | n | git status picker | neogit status | K | L; neogit → `<leader>gn` |
| `<leader>gd` | n | git diff (hunks) picker | codediff show diff | K | L; codediff → `<leader>gv` |
| `<leader>gD` | n | git diff (origin) picker | git status picker | K | L; drop K's (dup of `<leader>gs`) |
| `<leader>gp` / `gP` | n | GitHub PRs (open/all) | neogit push / push variant | K; PRs via octo `<leader>gr` | L; push → `<leader>gu` / `gU` |
| `<leader>gI` | n | GitHub issues (all) | octo search issues | K (≈ same intent) | L |
| `<leader>gS` | n | git stash picker | octo search | K; stash: drop | L; octo → `<leader>gO*` group |
| `<leader>gl` | n | git log (root) | octo list repos | K; log stays on `<leader>gL` | L; octo → `<leader>gO*` |
| `<C-k>` | i | signature help | open line below (`<C-O>o`) | K (K has sig help on i`<c-l>`) | L; drop K's |
| `<C-s>` | n (t) | save file | neogit status | K in n/t (save stays in i/x/s) | L |
| `<A-j>` / `<A-k>` | n | move line | next/prev hunk (gitsigns buffer-local) + nvim-tree local | K (move.nvim covers visual) | L; K's = L `]h`/`[h` (drop) |
| `<C-Up>` / `<C-Down>` | n | resize height | visual-multi add cursor | K (resize via `<C-w>` hydra) | L; VM add cursor → ? |
| `<C-Left>` / `<C-Right>` | n | resize width | sibling-swap | K | L; swap → ? (`<space><Left/Right>` swap-with-opp stays) |
| `]c` / `[c` | n | TS next/prev class | next/prev hunk (gitsigns local) | K; class jump: drop | L; K's = `]h`/`[h` |
| `]C` / `[C` | n | TS class end | next/prev dirty git file | K | L; dirty file → ? |
| `]d` / `[d` | n | next/prev diagnostic | next/prev breakpoint | K; diagnostics nav = K `]w`/`[w` | L; breakpoints → ? |
| `]w` / `[w` | n | next/prev **warning** | next/prev **any** diagnostic (+center) | K | L |
| `<Down>` / `<Up>` | n x | gj / gk | scroll `<C-e>`/`<C-y>` | K | L |
| `<C-w>` | n | which-key `<c-w>` popup (+ `<leader>w` proxy, `<c-w><space>` loop) | window-resizer hydra body | K; drop `<leader>w` proxy + `<c-w><space>` | L; drop K's hydra (= `<c-w><space>`) |
| `<c-f>` / `<c-b>` | n i s | noice: scroll LSP docs | (K uses `<c-d>`/`<c-u>` for that) | K's keys; drop L's | L's keys |
| `<leader>e` | n | explorer (off, D16) | FeMaco edit code block | K | L-style: `<leader>e`/`E` → nvim-tree; FeMaco → `<leader>cE`? |
| `<leader>ft` / `fT`, `<c-/>` | n t | snacks terminal | (toggleterm on `<C-t>`) | follow D21: drop L's or point at toggleterm | L |

¹ K `<leader>o`/`<leader>O` = "find files matching the current file", **not** recent files.

### B. Prefix collisions: Koala binds a key that LazyVim uses as a group prefix

With `timeoutlen=300`, the short key fires only after the timeout, and any keys typed after it that match a group entry get **hijacked**.

| Prefix | LazyVim group | KoalaVim single key | What breaks if both stay |
|---|---|---|---|
| `<leader>c` | code: `ca cA cc cC cd cf cF cl cm co cr cR cs cS` + lang extras `ch cv cp cM cu cD cV` | `"_c` (change, no yank) | `<leader>cc` (change line) → codelens; `<leader>cf{x}` / `<leader>cl` / `<leader>ca(` → format / Lsp info / code action |
| `<leader>d` | debug: `da db dB dc dC de dg di dj dk dl do dO dP dr ds dt du dw dp*` | `"_d` (delete, no yank) | **severe**: `<leader>dw`, `<leader>di(`, `<leader>dj`, `<leader>dk`, `<leader>dt{x}`, `<leader>db` all trigger DAP |
| `<leader>s` | search: ~30 keys (`sg sw sr sR ss sS sh sk sm …`) | spell **hydra body** | the hydra grabs the whole prefix |
| `<leader>b` | buffer: `bb bd bD bo bi bp bP br bl bj` | build & deploy | build only after 300ms; mild |
| `<leader><Tab>` | tabs: `<tab>l o f <tab> ] d [` | `b#` last buffer | `<leader><Tab>` delayed; `<leader><Tab><Tab>` = new tab |
| `<leader>gh` | hunks: `ghs ghr ghS ghu ghR ghp ghb ghB ghd ghD` | codediff file history | history delayed. (K hunks live on `<leader>h*`, not contested) |
| `<leader>gi` | single key: issues picker | octo prefix `gic` `gil` | L's `gi` delayed |
| `<leader>fc` | single key: find config file | prefix `fcw fcW fcd fcdw fcf` | L's `fc` delayed |
| `<leader>fn` | single key (n): new file | prefix `fnr fnc` (+ `<leader>fn` in x = spectre visual) | L's `fn` delayed |

### C. LazyVim overrides of vim defaults that KoalaVim never touched

KoalaVim users haven't had these. They don't collide with a Koala key, but they change familiar behavior: `H`/`L` → prev/next buffer, `<A-j>/<A-k>` move line (i, v), `<C-s>` save (i/x/s), `<esc>` clears hlsearch, insert `, . ;` undo breakpoints, x-mode `<`/`>` reselect, `gco`/`gcO`, `[b ]b [B ]B`, `]f [f ]a [a` (TS; K already uses `]a` via `<M-]>`), `]] [[` (illuminate refs), `gy`, `gK`, `<leader>-` / `<leader>|`.

### D. Same intent, different binding (no collision, so both would exist)

| Intent | LazyVim | KoalaVim |
|---|---|---|
| format | `<leader>cf` | `<leader>F` |
| hunks | `]h [h`, `<leader>gh*` | `]c [c`, `<M-j>/<M-k>`, `<leader>h*` |
| rename / code action / line diag | `<leader>cr` / `<leader>ca` / `<leader>cd` | `<F2>` / `<F4>` / `<leader>L` |
| inlay hints toggle | `<leader>uh` | `<leader>T` |
| trouble | `<leader>xx` = all, `xX` = buffer | `<leader>t`, `xx` = **buffer**, `xX` = workspace (semantics swapped) |
| md preview | `<leader>cp` | `<leader>up` |
| implementation / type def | `gI` / `gy` | `gi` / `gt` (override vim `gi` / `gt`) |
| buffer nav | `H`/`L`, `[b`/`]b` | `<C-,>`/`<C-.>`, `<leader>1..0` |
| splits | `<leader>-` / `<leader>|` | `<M-o>` / `<M-e>` |
| refs next/prev | `]]` / `[[` | `<C-n>` / `<C-p>` |
| debug | `<leader>d*` | `<F5>`–`<F12>`, `<leader>k`, `<leader>rc/rp` |
| explorer | `<leader>e/E` | `<M-m>` / `<M-M>` |
| terminal | `<c-/>` | `<C-t>` |
| file history | `<leader>gf` | `<leader>gh` |

### koala flavor: relocation map (D47)

Applied after D46, so the duplicates are already gone. Anything not listed keeps its LazyVim key.

**Code `<leader>c*` → `<leader>v*`** (includes lang extras)
`cA→vA` source action · `cc/cC→vc/vC` codelens · `cl→vl` LSP info · `cm→vm` Mason · `co→vo` organize imports · `cR→vR` rename file · `cs/cS→vs/vS` Trouble symbols/LSP · `cF→vF` format injected · clangd `ch→vh` · python `cv→vv` venv · vtsls `cM cu cD cV → vM vu vD vV`. Dropped as duplicates: `ca cr cd cf cp`. ⚠ rustaceanvim maps a buffer-local `<leader>cR` (code action) that collides with `vR` in rust buffers; the rust buffer-local one wins there.

**Debug `<leader>d*` → `<leader>r*`** (joins Koala's `rc` run-to-cursor, `rp` repl, rust `rr`/`rt`)
`dB→rB` · `da→ra` · `dg→rg` · `dj/dk→rj/rk` · `dl→rl` · `dP→rP` · `ds→rs` · `dt→rt` (rust buffers: rustaceanvim's testables win) · `dw→rw` · `du→ru` · python `dPt/dPc→rT/rC` · rust `dr→rd`. Profiler `dpp dph dps → <leader>uPp uPh uPs`. Dropped (Koala has F-keys / `rc` / `rp` / `<leader>k`): `db dc di dO do dC dr de`.

**Search `<leader>s*` → merged into `<leader>f*`** (`<leader>s` stays the spell hydra)

| LazyVim | → | | LazyVim | → |
|---|---|---|---|---|
| `sb` buffer lines | `fl` | | `sk` keymaps | `fk` |
| `sB` grep open buffers | `fG` | | `sl` loclist | `fQ` |
| `sp` plugin spec | `fP` | | `sq` quickfix | `fq` |
| `s"` registers | `f"` | | `sM` man | `fM` |
| `s/` search history | `f/` | | `sm` marks | `f'` |
| `sa` autocmds | `fa` | | `su` undo | `fu` |
| `sc` command history | `f:` | | `st` / `sT` todo | `ft` / `fT` |
| `sC` commands | `fC` | | `snl sna snt` noice | `fNl fNa fNt` |
| `sd` / `sD` diagnostics | `fd` / `fD` | | `sr` replace | spectre (`fnr` already) |
| `sh` / `sH` help / hl | `fh` / `fH` | | `sj` jumps | `fj` |

Dropped as duplicates of Koala keys: `sg` (= `fw`), `sG` (= `fcd`), `sw sW` (= `fcw fcW`), `sR` (= `fr`), `ss` (= `gs`), `sS` (= `fs`), `si` (= `fi`), `snh snd` (= `<leader>n`, `<leader>un`).
LazyVim's own `f*` under koala: `fr` recent → **`fo`**, `fR` recent (cwd) → **`fO`**, `fc` config file → **`fv`**, `fn` new file → dropped, `ft/fT` terminal → dropped (D21, keys reused for todo). `fB fF fg fp` unchanged.
Final `<leader>f` namespace check: Koala `ff fw fm fb fr fs fi fI fc{f,w,W,d,dw} fn(x) fnr fnc` + LazyVim `fB fF fg fp fo fO fv` + merged `fl fG fP f" f/ fa f: fC fd fD fh fH fj fk fQ fq fM f' fu ft fT fNl fNa fNt` → no duplicate keys, and no single key is also used as a prefix.

**Buffer `<leader>b*` → `<leader>q*`**: `bD→qD` · `bi→qi` · `bp/bP→qp/qP` (pin) · `br/bl→qr/ql` · `bj→qj` (pick). Dropped: `bb bd bo` (= `<leader><Tab>`, `qq`, `qa`).
**Tabs `<leader><tab>*`**: all dropped (Koala covers tabpages: `g1..g0`, `<C-1..0>`, `gq`, `<M-t>`, `<leader>,`/`.`).
**Lazy**: `<leader>l` → `<leader>zz` (Lazy), `<leader>L` → `<leader>zl` (LazyVim changelog), plus `<leader>zx` → `:LazyExtras`.

### lazyvim flavor: homes for Koala features that lost their key (D44, confirmed 2026-10-21, see also D48–D53)

| Koala feature | Koala key | lazyvim flavor key |
|---|---|---|
| diagnostics mode cycle | `<leader>l` | `<leader>uv` |
| diff-viewer hydra | `<leader>gg` | `<leader>gV` |
| codediff show diff | `<leader>gd` | `<leader>gv` |
| neogit status | `<leader>gs`, `<C-s>` | `<leader>gn` |
| neogit push / push variant | `<leader>gp/gP` | `<leader>gu/gU` |
| octo (issues, PRs, repos, search) | `<leader>gI gR gS gr gl gic gil` | `<leader>gO*` group |
| visual-multi add cursor up/down | `<C-Up>/<C-Down>` | `<M-Up>/<M-Down>` |
| sibling-swap left/right | `<C-Left>/<C-Right>` | `<M-Left>/<M-Right>` |
| next/prev dirty git file | `]C`/`[C` | `]G`/`[G` |
| next/prev breakpoint | `]d`/`[d` | `]r`/`[r` |
| FeMaco edit code block | `<leader>e` | `<leader>cE` |
| insert: open line below | i`<C-k>` | dropped |
| arrow-key scroll | `<Down>/<Up>` | dropped |

### Koala-internal clashes found along the way (fix regardless of flavor)
- `<leader>n`: notification history globally, but c/cpp buffers remap it to "add `\r\n`" (`servers/cpp.lua`).
- `<leader>t`: Trouble toggle and the markdown checkmate `<leader>t*` prefix.
- `<RightMouse>`: LSP hover (`lsp/general.lua`) and a debug mapping (`debug.lua:284`).
- `<M-z>`: `ai.lua` and `editor.lua` (NeoZoom).
- `<M-e>`: vsplit (`config/keymaps/splits.lua`) and `terminal.lua:17`.
- `<C-h/j/k/l>` n: Navigator, plus `ai.lua` `<c-h/j/k/l>`. Check whether those are buffer-local to sidekick.

---

## Inventory: overlap map

Legend: L = LazyVim core/extra, K = KoalaVim. "?" = undecided.

| Concern | LazyVim | KoalaVim | Call |
|---|---|---|---|
| Framework / loader | `LazyVim.*`, extras, `lazyvim.json` | `require_dir` config loading, globals (`LSP_SERVERS`, `CONFORM_FORMATTERS`, `NONE_LS_SRCS`, `HYDRAS`) | **L** (D4) |
| User config surface | Lua `opts` + `vim.g.lazyvim_*` | `kvim.conf` JSON (+ schema, repo/user/default merge) | kvim.conf + global `flavor` (D18); loaded early |
| Keymaps | full leader layout (`<leader>c` code, `d` debug, `b` buffer, `u` ui toggles, `x` diag, `s` search, `f` find, `w` windows, `q` quit/session) | `<leader>c/C/d/D` no-yank, `<leader>b/B` build, `<leader>1..0` buffers, `<leader>qq/qa/qA`, `<leader>y/p` os clipboard, `<leader>F` format, `<leader>l` diag cycle, `<leader>L`, `<leader>T`, `<F2>/<F4>`, `<M-e/o/q/w>` splits, `<C-n/p>` refs | flavor (D7, D18) |
| which-key | ✅ spec + groups | stub | **L** (D1) |
| Completion | blink.cmp (default) / nvim-cmp extra | nvim-cmp + many custom sources | **fuse**: L nvim-cmp extra + K sources (D2, D5) |
| Snippets | friendly-snippets (native/luasnip) | nvim-snippy + ofirgall/vim-snippets | **L** + converted Koala snippets (D10) |
| Autopairs | mini.pairs | nvim-autopairs (cmp confirm hook) | **K** (D22) |
| Comments | ts-comments + native `gc` | Comment.nvim + ts-context-commentstring | **K** (D23) |
| Textobjects | mini.ai (rich custom objs) | mini.ai + various-textobjs + TS textobjects | **L** mini.ai + K extras (D30) |
| Motion | flash.nvim (`s`, `S`, `r`, `R`) | leap + flit; `s` disabled globally, surround on `s`? | **K** (D17) |
| Surround | mini.surround extra (`gs`) | nvim-surround | **K** (D24) |
| LSP setup | `opts.servers` + `setup` hooks + per-server `keys` w/ `has=` capability gating, mason-lspconfig auto-enable, lang extras | `LSP_SERVERS` global table / resolvers, `LSP_CAPS` from cmp, semantic tokens off, `dont_format`, `mason` name override | **L** + K deltas (D11) |
| Diagnostics UX | `vim.diagnostic.config` virtual_text | 3-mode cycle: diagflow / lsp_lines / errors-only vtext (`<leader>l`) | **K** cycle, native backend (D13) |
| LSP UI | native rename/code_action, Snacks.words refs | lspsaga (rename, code action, lightbulb, line diag), illuminate, navbuddy, dr-lsp counts | illuminate (L extra + K keys), drop lspsaga (D14); navic/navbuddy/dr-lsp **K** (D34) |
| Inlay hints | native, auto-enable | inlay-hints.nvim fork (EOL renderer), toggle `<leader>T` | **K** fork (D14) |
| Formatting | `LazyVim.format` + conform, format-on-**save**, `<leader>uf` toggle, conform `config` must be LazyVim's | conform + format-on-**leave** (writes buffer), blacklist / blacklist_ft via kvim.conf, `<leader>F` | **L** (D6) |
| Linting | nvim-lint | none-ls (diagnostics/code_actions only; formatting forbidden) | **L** nvim-lint (D12) |
| Treesitter | main branch, `LazyVim.treesitter` | main branch too (`get_available`), endwise, matchup, context, jsonpath | **L** + K extras (D35) |
| Picker | snacks picker (default) | fff.nvim (files/grep) + snacks picker (custom layout) | **fuse** fff + snacks behind LazyVim.pick (D15) |
| Explorer | snacks explorer | nvim-tree (+ fff/spectre/codediff actions) | **K** (D16) |
| Statusline | lualine (LazyVim layout) | lualine (ofirkai statusline + Koala components) | flavor (D19) |
| Bufferline | bufferline | bufferline (ofirkai tabline) + scope.nvim | flavor (D19) |
| Notifications / cmdline | noice | noice + custom routes + fidget | fuse noice + fidget (D27) |
| Dashboard | snacks dashboard | alpha fork (Koala shortcuts) | flavor (D20) |
| Indent guides | snacks.indent / scope | indent-blankline | **K** (D28) |
| Statuscolumn | snacks.statuscolumn | statuscol.nvim | **K** (D28) |
| vim.ui.input/select | snacks.input / picker | dressing (+ snacks ui_select) | **K** (D28) |
| Terminal | snacks.terminal | toggleterm + term-edit | flavor (D21) |
| Sessions | persistence | possession (+ cwd session logic) | flavor (D21) |
| Git | gitsigns (LazyVim maps) + lazygit via snacks | gitsigns, neogit fork, fugitive, codediff fork, flog, git-messenger, octo, inlinediff, gitlinker | fuse gitsigns, **K** git UI (D32) |
| Search/replace | grug-far | spectre, muren | **K** (D25) |
| Trouble | trouble | trouble fork | **L** v3 (D26) |
| Todo comments | todo-comments | todo-comments | same plugin, merge opts |
| DAP | dap.core extra | nvim-dap + ui + virtual-text + goto-breakpoints | **fuse** (D29) |
| AI | sidekick extra | sidekick fork + heavy Koala layer | **K** |
| Modal / hydras | `<c-w><space>` which-key loop | hydra.nvim + 5 hydras | **K** |
| Koala-only (no L equivalent) | — | AutoSave, guess-indent, NeoZoom, FeMaco, open/open-jira, retrail, Navigator (zellij/herdr), hex, suda, genghis, highlight-undo, undotree, interestingwords, marks, nerdy, yanky, substitute, toggler, treesj, sibling-swap, visual-multi, move, numb, colorizer, colorful-winsep, smear-cursor, vimade, git-blame, navic, kv modes, update checker, half-screen | **K** (check each for LazyVim extra equivalents: yanky, smear-cursor, navic, dial, mini-move, illuminate exist as extras) |

---

## Log

- 2026-10-20 — kickoff. Inventory built. D1–D3 from initial brief.
- 2026-10-20 — D4 spec layer, D5 nvim-cmp extra + Koala sources, D6 LazyVim format-on-save. Keymaps: user wants them configurable through kvim.conf → Q2 refined.
- 2026-10-20 — D7 keymap preset (default koala), D8 autosave skips fmt, D9 blacklist knobs mapped, D10 native snippets + convert Koala's.
- 2026-10-20 — D11 lang extras + deltas, D12 nvim-lint, D13 diag cycle on native, D14 LSP UI (keep illuminate/inlay fork/semtok off, drop lspsaga).
- 2026-10-20 — D15 fff+snacks behind LazyVim.pick, D16 nvim-tree, D17 leap+flit. Statusline: user wants it configurable → 'presets' pattern emerging (keymaps, statusline).
- 2026-10-20 — D18 single global `flavor` (D7 folded into it), D19 statusline, D20 dashboard, D21 sessions+terminal all follow flavor.
- 2026-10-20 — D22–D25: editing basics all Koala (autopairs, Comment.nvim, nvim-surround, spectre+muren).
- 2026-10-20 — D26 trouble v3, D27 noice fuse + fidget, D28 Koala ibl/statuscol/dressing, D29 DAP fuse, D30 LazyVim mini.ai (recommended).
- 2026-10-20 — D31 LazyVim config base + Koala on Defaults events, D32 gitsigns fuse, D33 go extra + go.nvim cmds, D34 keep navic/navbuddy/dr-lsp. Added 'still open' list.
- 2026-10-20 — D35 treesitter L+K, D36 keep Koala specs over duplicate extras, D37 snacks bigfile/quickfile/scroll/notifier on, D38 no lightbulb.
- 2026-10-20 — D39 Koala hard-codes extras + :LazyExtras, D40 lockfile pin, D41 news on, D42 ofirkai gaps upstream. Only the contested-keys table is left open.
- 2026-10-20 — Contested-keys table built (A: 30 hard collisions, B: 9 prefix collisions, C: vim-default overrides, D: same-intent duplicates, plus Koala-internal clashes).
- 2026-10-20 — Key policies: D43 koala keys win + relocate LazyVim groups, D44 lazyvim flavor keeps Koala features minus duplicates, D45 koala drops LazyVim vim-default overrides, D46 koala drops same-intent duplicates.
- 2026-10-20 — D47 relocation targets (v / r / merge into f / q / drop tabs). Full relocation map + lazyvim-flavor homes drafted.
- 2026-10-20 — OpenSpec changes created: lazyvim-foundation, lazyvim-lsp-formatting, lazyvim-completion, lazyvim-ui-editing, flavor-keymaps (all valid --strict). Bootstrap finding: koala_init.lua puts user spec BEFORE KoalaVim spec and template init.lua recursively requires user config/ (double-load with LazyVim) — handled in lazyvim-foundation D1/D4/D5.
- 2026-10-20 — Implemented `lazyvim-foundation`, `lazyvim-lsp-formatting` and `lazyvim-completion` (Sonnet subagents, verified headless). Integration fixes: blink default extra (D59), lockfile generator, ofirkai `feat/lazyvim` branch (D56).
- 2026-10-21 — Implemented `lazyvim-ui-editing`: flavor-driven statusline, dashboard, sessions and terminal; trouble v3 (D60); snacks bump (D57); lockfile covers every flavor (D58).
- 2026-10-21 — Implemented `flavor-keymaps`: keymap engine (D54), user decisions D48–D52, adjustments D53, which-key per flavor (D55), `make test-keymaps` passing in both flavors.
- 2026-10-21 — Completed `lazyvim-lsp-formatting` 8.4 (DAP close fix, D62). Log moved from `tmp/lazyvim/` to `docs/decisions/lazyvim-migration.md` and committed.
