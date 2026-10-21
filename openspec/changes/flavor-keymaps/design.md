## Context

Where keys are defined once phases 1–4 are in:

```
 LazyVim                                         KoalaVim
 lazyvim.config.keymaps (global, VeryLazy)       config/keymaps/*.lua (after LazyVimKeymapsDefaults)
 plugin spec keys (snacks picker/util, trouble,  plugin spec keys (pickers, git, ai, coding, ...)
   todo, which-key, dap.core, noice, bufferline, map_buffer in on_attach / FileType autocmds
   conform, mason, lang extras ...)              hydra bodies (<leader>s, <leader>gg, <C-w>)
 lspconfig opts.servers["*" | x].keys (has=)
 gitsigns on_attach, rustaceanvim on_attach (vim.keymap.set)
```

The audit, classified A–D (collision tables and the full relocation map), is the input for the contested-keys table.

## Goals / Non-Goals

**Goals:** One action per contested key per flavor. The relocation and removal rules applied mechanically rather than by hand-editing each spec. A verifiable no-ambiguous-prefix invariant.

**Non-Goals:** Redesigning KoalaVim's non-contested keys. Per-key user overrides in kvim.conf (the flavor is the only switch; users override in Lua).

## Decisions

### D1. Data-driven table
`KoalaVim.keymaps.contested` returns entries:
```lua
{ lhs = '<leader>l', mode = 'n',
  koala   = { action = koala_cycle_diag },          -- winner under koala
  lazyvim = { relocate_koala_to = '<leader>uv' },   -- koala feature's home under lazyvim
}
```
It also holds prefix rules (`{ from = '<leader>c', to = '<leader>v', flavor = 'koala', except = { 'ca','cr','cd','cf','cp' } }`), the D45 list of vim-default overrides to strip, and the D46 duplicate list. A single table keeps the documentation, implementation and test in sync.

### D2. Applying the table to plugin specs
lazy.nvim merges `keys` with `Plugin.values()`, which accepts a function: `keys = function(plugin, keys) return remap(plugin.name, keys) end`. KoalaVim adds a minimal spec per affected plugin (`{ 'folke/trouble.nvim', keys = remap.keys }`, …). Because KoalaVim specs import after LazyVim's and the extras, the function sees the fully merged list. `remap` (koala flavor):
1. drops entries in the duplicate/strip lists
2. rewrites lhs prefixes per prefix rules (keeping mode/desc/ft)
3. drops entries whose lhs equals a KoalaVim-owned key

In the lazyvim flavor, `remap` is the identity on LazyVim keys, and KoalaVim's own specs drop their duplicates and apply `relocate_koala_to`.

### D3. Applying the table to non-spec keymaps
- LazyVim globals (`lazyvim.config.keymaps`): keep `defaults.keymaps = true` and post-process on `User LazyVimKeymapsDefaults` (before KoalaVim's keymaps load). Delete stripped/duplicate lhs and re-map relocated ones (e.g. `<leader>l` Lazy → `<leader>zz`, `<leader>qq` quit-all → `<leader>qQ`, `<leader>ud`/`uD` kept as LazyVim's). *Alternative:* `defaults.keymaps = false` and re-add what KoalaVim wants. Rejected because it loses LazyVim's toggles and git maps for little gain, and the post-process reuses the same table.
- LSP keys: an lspconfig `opts` function rewrites `opts.servers[*].keys` lists with the same `remap` before LazyVim's config consumes them. `has=` gating is preserved.
- gitsigns: one `on_attach` that calls LazyVim's mappings (lazyvim flavor) or KoalaVim's (koala flavor), then KoalaVim's non-duplicate feature maps.
- rustaceanvim / any `vim.keymap.set` in `on_attach`: KoalaVim overrides the `server.on_attach` opts to call the original and then apply `remap` to the buffer-local maps it created (`nvim_buf_get_keymap` diff before/after).

### D4. KoalaVim's own keys become flavor-aware
KoalaVim keys that lose under the lazyvim flavor are defined through a helper `kmap(spec)`. Under `lazyvim` it skips duplicate keys and moves displaced ones to `relocate_koala_to`. Hydra bodies (`<leader>s` spell, `<leader>gg` diff viewer, `<C-w>` resizer) use the same lookup.

### D5. which-key groups per flavor
- koala: drop LazyVim's group specs for `<leader>c d s b <tab> w`, `gs`, `<leader>gh`. Add `<leader>v` code, `<leader>r` run/debug, `<leader>f` find/search, `<leader>q` quit/buffers, `<leader>z` lazy, `<leader>a` ai, `<leader>h` hunks, `<leader>uP` profiler, `<leader>fN` noice.
- lazyvim: LazyVim's groups, plus `<leader>a` ai, `<leader>gO` octo, `<leader>uP` profiler.

Implemented with a which-key `opts` function that filters `opts.spec` by lhs and appends KoalaVim groups.

### D6. Invariant check
`KoalaVim.keymaps.check()`: after VeryLazy and with lazy keys handlers installed, collect `nvim_get_keymap(mode)` for n/x/o/i plus the buffer-local keymaps of a scratch buffer with gitsigns/LSP attached (headless test fixture). Assert:
- no lhs in the `<leader>` namespace is both a complete mapping and a strict prefix of another lhs in the same mode (exceptions allowlisted, e.g. intentional hydra bodies with `invoke_on_body`)
- every contested key resolves to its flavor's winner (compare `desc` or a callback tag)

Exposed through `:checkhealth KoalaVim` and a `make test-keymaps` headless run for both flavors.

### D7. Koala-internal fixes
- `<leader>n` CRLF (c/cpp) → `<leader>vn` (koala) / `<leader>cn` (lazyvim)
- checkmate `<leader>t*` → `<localleader>t*`, scoped to markdown buffers. `<leader>t` (Trouble) keeps the leader key.
- `<RightMouse>` hover vs debug: debug's is buffer-local during sessions. Keep it and verify that it doesn't leak.
- `<M-z>` AI zoom vs NeoZoom: AI's only in sidekick buffers (ft-scoped). Same for `<M-e>` (terminal ft) and `<c-h/j/k/l>` in AI buffers.

## Risks / Trade-offs

- [lazy.nvim `keys` functions run at spec resolution, so new upstream LazyVim keys appear without anyone noticing] → The invariant test runs in CI on each lockfile bump and fails on new collisions.
- [`on_attach` keymap diffing is fragile] → Use it only for rustaceanvim. Prefer opts-level key lists wherever the plugin exposes them.
- [In the koala flavor, LazyVim's documentation no longer matches the keys (e.g. LazyVim's `<leader>co` organize-imports is `<leader>vo`)] → Generate a keymap cheat sheet per flavor from the table.

## Implementation notes (as built)

- **Engine:**
  - `lua/KoalaVim/keymaps/{contested,remap,check,init}.lua`, plus `kmap`/`kmap_buffer`/`kkeys`/`klhs` in `utils/map.lua`.
  - `contested.lua` holds `entries` (per-side `to`/`drop`; `win` pins one winner in both flavors), `prefixes` (longest `from` wins; explicit entries take precedence), `adds` (keys a flavor adds) and `allow_prefix`.
  - The `desc` substrings in `contested.lua` are how `check()` tells who owns a key, so keep them in sync with the real descriptions.
- **D2 correction:** a lazy.nvim `keys = function` fragment only sees fragments merged **before** it. KoalaVim's own key lists therefore go through `kkeys`, which marks them so `remap.keys` leaves them alone. The remap fragments live in `plugins/lazyvim_keys.lua` (with `optional = true`) and `plugins/lsp/keys.lua`, which lazy.nvim imports last for nvim-lspconfig.
- **D3 additions:**
  - LazyVim never creates a global key a lazy `keys` stub already holds (`safe_keymap_set`). Keys moved onto such a spot are created through `adds` instead (`<leader>zz/zl/zx`).
  - LazyVim also creates keys from plugin `config`, ftplugins, `on_attach` and LSP attach. bracket-repeat wraps every `[x`/`]x` callback.
  - `remap.watch()` re-sweeps on `FileType`, `LspAttach` and `User LazyLoad`, and only touches maps whose callback lives in `lazyvim/`. That covers illuminate and rustaceanvim without wrappers; rustaceanvim is wrapped as well, so its result doesn't depend on timing.
- **Which-key:**
  - koala: LazyVim's `<tab> c d dp s b w q gh gs` groups are removed. Added: `v` code, `r` run/debug, `q` quit/buffers, `z` lazy, `a` ai, `h` hunks, `uP` profiler, `fN` noice, `fc`/`fcd`.
  - lazyvim: LazyVim's groups plus `a`, `gO`, `r` run/build, `h`, `fC`/`fCd`, and `fN`, which here holds KoalaVim's spectre keys. No `uP` in lazyvim (the profiler stays on `<leader>dp`).
- **Adjustments made during implementation:**
  - koala:
    - `<C-s>` is KoalaVim's in every mode.
    - LazyVim's `[b ]b [B ]B` and illuminate's `]] [[` are dropped (they collide with KoalaVim's treesitter motions).
    - `<leader>xX` is dropped (same as KoalaVim's `<leader>t`).
    - dap `dt` is dropped (`<F6>`), so a moved `<leader>rt` can't shadow rust testables.
  - lazyvim:
    - KoalaVim's treesitter block jumps `]b [b ]B [B` → `]o [o ]O [O`.
    - KoalaVim's `fc*`/`fn*` → `fC*`/`fN*`, because LazyVim's `fc` and `fn` are single keys.
    - `<leader>e`/`<leader>E` open nvim-tree.
    - The `<C-w>` resizer hydra is dropped (LazyVim's which-key `<c-w>` popup wins).
    - `gK` is unbound (LazyVim's signature help is gated on the LSP supporting it).
  - Checkmate's metadata keys `<leader>Tp/Ts/Td` → `<localleader>T*`, so `<leader>T` (inlay hints) is no longer an ambiguous prefix.
  - Go's `<leader>fln` → `<leader>vp` (koala) / `<leader>cp` (lazyvim). The block is dead code while go.nvim is disabled.
  - c/cpp CRLF `<leader>n` → `<leader>vn` (koala) / `<leader>cn` (lazyvim).
  - checkmate `<leader>t*` → `<localleader>t*`.
- **Tests:**
  - `make test-keymaps` (`dev/test_keymaps.{sh,lua}`) runs `check()` in both flavors on lua, go, rust, markdown and C buffers, with LSP and gitsigns attached. A server that isn't installed is skipped and reported.
  - The script unsets the inherited `kv` session variables (`KOALA_*`, `NVIM_APPNAME`, `KV_ENV`) and cleans up lua-language-server's per-file logs.
  - Filetype-scoped entries are only verified for filetypes in the fixture; python, typescript and zig aren't covered yet.
  - `check()` can't see two sources setting the same key when only one of them is in the table.
- **Docs:** `docs/keymaps.md` is generated by `make gen-keymaps-doc` (`scripts/gen_keymaps_doc.lua`). The prose describing the group prefixes is hand-written in the generator.

## Resolved Questions

- lazyvim-flavor keys for KoalaVim features whose key starts a LazyVim group (decided 2026-10-21):
  - black-hole change/delete → `<leader>C` / `<leader>D` as operators. KoalaVim's `"_C`/`"_D` line variants are dropped in the lazyvim flavor; use `<leader>C$` / `<leader>D$` instead.
  - build & deploy → `<leader>rb` / `<leader>rB`. The `r` group is free in LazyVim's layout.
  - spell hydra → `<leader>uZ`. `<leader>uz` is LazyVim's zen-mode toggle, so the engine's first proposal was wrong.
- KoalaVim-internal clashes found by `check()` (decided 2026-10-21):
  - `<leader>fcd` (find in current dir) becomes `<leader>fcdd`, so `<leader>fcd` is a group holding `fcdd` and `fcdw`.
  - `<C-.>` keeps today's runtime behavior: bufferline next in normal mode (KoalaVim's keymaps load later and win), Sidekick toggle in insert, terminal and visual modes. Sidekick's spec drops normal mode.
- The rest of the koala-flavor relocation map (code→`<leader>v`, debug→`<leader>r`, search merged into `<leader>f`, buffers→`<leader>q`, Lazy→`<leader>z`) and the lazyvim-flavor homes are implemented as recorded in the audit. They're adjusted only where phases 2–4 changed the underlying keys (trouble v3, LazyVim's illuminate, mini.ai textobjects).
