<!-- Generated from lua/KoalaVim/keymaps/contested.lua - do not edit manually. -->
<!-- Run: make gen-keymaps-doc (nvim -l scripts/gen_keymaps_doc.lua) -->

# Keymaps per flavor

KoalaVim runs on top of LazyVim, both bind keys. The `flavor` option (`~/.kvim.conf`, `{"flavor": "koala" | "lazyvim"}`)
decides who owns a contested key; the loser is moved or dropped. This sheet lists, per flavor, what moved, what was
dropped and what KoalaVim adds. Source of truth: [`contested.lua`](../lua/KoalaVim/keymaps/contested.lua), verified
by `require("KoalaVim.keymaps").check()` (`make test-keymaps`, `:checkhealth KoalaVim`).

`<leader>` is `<space>`. A key listed once with a moved/dropped result is not bound to the original action anymore.

## Group prefixes

| Prefix | `koala` flavor | `lazyvim` flavor |
| --- | --- | --- |
| `<leader><tab>` | - | tabs |
| `<leader>C` | - | change without yanking (operator) |
| `<leader>D` | - | delete without yanking (operator) |
| `<leader>a` | ai | ai |
| `<leader>b` | build & deploy | buffer |
| `<leader>c` | change without yanking (operator) | code |
| `<leader>d` | delete without yanking (operator) | debug |
| `<leader>dp` | - | profiler |
| `<leader>f` | find/search (LazyVim's `<leader>s*` merged in) | file/find |
| `<leader>fC` | - | current word/dir |
| `<leader>fCd` | - | current dir |
| `<leader>fN` | noice | spectre |
| `<leader>fc` | current word/dir | - |
| `<leader>fcd` | current dir | - |
| `<leader>g` | git | git |
| `<leader>gO` | - | octo |
| `<leader>gh` | - | hunks |
| `<leader>h` | hunks | hunks |
| `<leader>q` | quit/buffers (LazyVim's `<leader>b*` merged in) | quit/session |
| `<leader>r` | run/debug | run/build |
| `<leader>s` | spell fixer | search |
| `<leader>u` | ui | ui |
| `<leader>uP` | profiler | - |
| `<leader>v` | code | - |
| `<leader>w` | - | windows |
| `<leader>x` | diagnostics/quickfix | diagnostics/quickfix |
| `<leader>z` | lazy | - |

- **koala**: KoalaVim's layout. LazyVim's code group `<leader>c` moves to `<leader>v`, debug `<leader>d` to
  `<leader>r`, buffers `<leader>b` to `<leader>q`, search `<leader>s` merges into `<leader>f`, and its lazy keys
  (`<leader>l`, ...) to `<leader>z`. `<leader>c`, `<leader>d` and `<leader>s` are KoalaVim's black-hole change /
  delete and spell fixer.
- **lazyvim**: LazyVim's layout is intact. KoalaVim keys that sit under a LazyVim single key move into a family
  next to it (`<leader>fc*` to `<leader>fC*`, `<leader>fn*` to `<leader>fN*`, Octo to `<leader>gO*`, build / deploy to
  `<leader>r*`).

Which-key groups KoalaVim registers: **koala** `<leader>v` code, `<leader>r` run/debug, `<leader>q` quit/buffers, `<leader>z` lazy, `<leader>a` ai, `<leader>h` hunks, `<leader>uP` profiler, `<leader>fc` current word/dir, `<leader>fcd` current dir, `<leader>fN` noice; **lazyvim** `<leader>a` ai, `<leader>gO` octo, `<leader>r` run/build, `<leader>h` hunks, `<leader>fC` current word/dir, `<leader>fCd` current dir, `<leader>fN` spectre.

## `koala` flavor

KoalaVim wins contested keys; LazyVim's bindings are moved or dropped.

### LazyVim keys moved or dropped

| Key | Mode | Action | Key now does | Result |
| --- | --- | --- | --- | --- |
| `<leader>l` | n | Lazy | Cycle between lsp diagnostics mode | moved to `<leader>zz` |
| `<leader>L` | n | LazyVim Changelog | show Problem | moved to `<leader>zl` |
| `<leader>qq` | n | Quit All | Close current tab | moved to `<leader>qQ` |
| `<leader>,` | n | Buffers | Previous tabpage | dropped, use `<leader>fb` |
| `<leader>.` | n | Toggle Scratch Buffer | Next tabpage | dropped, use `<leader>S` |
| `` <leader>` `` | n | Switch to Other Buffer | Replace surround to \` | dropped, use `<leader><Tab>` |
| `<leader>fr` | n | Recent | Find resume | moved to `<leader>fo` |
| `<leader>fR` | n | Recent (cwd) |  | moved to `<leader>fO` |
| `<leader>gg` | n | Lazygit | diff_viewer | dropped, use `<leader>gG` |
| `<leader>gs` | n | Git Status | Open Neogit | dropped (neogit `<leader>gs`) |
| `<leader>gd` | n | Git Diff (hunks) | Git show diff | dropped (codediff `<leader>gd`) |
| `<leader>gD` | n | Git Diff (origin) | Git dirtyfiles | dropped |
| `<leader>gp` | n | GitHub Pull Requests (open) | Git push | dropped (octo `<leader>gr`) |
| `<leader>gP` | n | GitHub Pull Requests (all) | Git push (alias) | dropped (octo `<leader>gR`) |
| `<leader>gI` | n | GitHub Issues (all) | Search Issues (Octo) | dropped (octo `<leader>gI`) |
| `<leader>gS` | n | Git Stash | Search (Octo) | dropped |
| `<leader>gl` | n | Git Log | List Repos (Octo) | dropped, use `<leader>gL` |
| `<leader>gi` | n | GitHub Issues (open) |  | dropped (octo `<leader>gic`) |
| `<leader>gf` | n | Git Current File History |  | dropped (codediff `<leader>gh`) |
| `<C-k>` | i | Signature Help | Insert new line | dropped, use `<c-l>` |
| `<C-h>` | n | Go to Left Window | Navigate | dropped (Navigator) |
| `<C-j>` | n | Go to Lower Window | Navigate | dropped (Navigator) |
| `<C-k>` | n | Go to Upper Window | Navigate | dropped (Navigator) |
| `<C-l>` | n | Go to Right Window | Navigate | dropped (Navigator) |
| `<C-s>` | n,i,x,s | Save File | Open Git Status | dropped (vim default) |
| `<M-j>` | n,i,v | Move Down | Jump to next git hunk | dropped (move.nvim / vim default) |
| `<M-k>` | n,i,v | Move Up | Jump to previous git hunk | dropped (move.nvim / vim default) |
| `<C-Up>` | n | Increase Window Height | add above | dropped (`<C-w>` hydra) |
| `<C-Down>` | n | Decrease Window Height | add below | dropped (`<C-w>` hydra) |
| `<C-Left>` | n | Decrease Window Width | Swap with left sibling | dropped (`<C-w>` hydra) |
| `<C-Right>` | n | Increase Window Width | Swap with right sibling | dropped (`<C-w>` hydra) |
| `]c` | n,x,o | Next Class Start | Jump to next git hunk | dropped, use `]]` |
| `]C` | n,x,o | Next Class End | Jump to next git dirty file | dropped |
| `]]` | n | Next Reference | goto_next_start @class.outer | dropped, use `<C-n>` |
| `]d` | n | Next Diagnostic | Goto next breakpoint | dropped, use `]w` |
| `]w` | n | Next Warning | Next diagnostic (warning) | dropped |
| `]e` | n | Next Error | Next error | dropped |
| `[c` | n,x,o | Prev Class Start | Jump to previous git hunk | dropped, use `[[` |
| `[C` | n,x,o | Prev Class End | Jump to previous git dirty file | dropped |
| `[[` | n | Prev Reference | goto_previous_start @class.outer | dropped, use `<C-p>` |
| `[d` | n | Prev Diagnostic | Goto prev breakpoint | dropped, use `[w` |
| `[w` | n | Prev Warning | Prev diagnostic (warning) | dropped |
| `[e` | n | Prev Error | Prev error | dropped |
| `<Down>` | n,x | Down | Down to scroll | dropped |
| `<Up>` | n,x | Up | Up to scroll | dropped |
| `j` | n,x | Down | Move down inside wrapped line | dropped (KoalaVim j) |
| `k` | n,x | Up | Move up inside wrapped line | dropped (KoalaVim k) |
| `<C-w><space>` | n | Window Hydra Mode |  | dropped (`<C-w>` hydra) |
| `<C-f>` | n,i,s | Scroll Forward |  | dropped (KoalaVim `<c-d>/<c-u>`) |
| `<C-b>` | n,i,s | Scroll Backward |  | dropped (KoalaVim `<c-d>/<c-u>`) |
| `<leader>ft` | n | Terminal (Root Dir) |  | dropped (toggleterm `<C-t>`) |
| `<leader>fT` | n | Terminal (cwd) |  | dropped (toggleterm `<C-t>`) |
| `<C-/>` | n,t | Terminal (Root Dir) |  | dropped (toggleterm `<C-t>`) |
| `<C-_>` | n,t |  |  | dropped (toggleterm `<C-t>`) |
| `<leader>fc` | n | Find Config File |  | moved to `<leader>fv` |
| `<leader>fn` | n | New File |  | dropped |
| `H` | n | Prev Buffer |  | dropped (vim default) |
| `L` | n | Next Buffer |  | dropped (vim default) |
| `]b` | n | Next Buffer | goto_next_start @block.outer | dropped (vim default) |
| `[b` | n | Prev Buffer | goto_previous_start @block.outer | dropped (vim default) |
| `]B` | n | Move buffer next | goto_next_end @block.outer | dropped (vim default) |
| `[B` | n | Move buffer prev | goto_previous_end @block.outer | dropped (vim default) |
| `<Esc>` | i,n,s | Escape and Clear hlsearch |  | dropped (vim default) |
| `,` | i |  |  | dropped (vim default) |
| `.` | i |  |  | dropped (vim default) |
| `;` | i |  |  | dropped (vim default) |
| `<` | x |  |  | dropped (vim default) |
| `>` | x |  |  | dropped (vim default) |
| `gco` | n | Add Comment Below |  | dropped (vim default) |
| `gcO` | n | Add Comment Above |  | dropped (vim default) |
| `<leader>-` | n | Split Window Below |  | dropped, use `<M-o>` |
| `<leader>\|` | n | Split Window Right |  | dropped, use `<M-e>` |
| `n` | n,x,o | Next Search Result | Auto recenter after n | dropped (vim default / KoalaVim n) |
| `N` | n,x,o | Prev Search Result | Auto recenter after N | dropped (vim default / KoalaVim N) |
| `<leader>cf` | n,x | Format |  | dropped, use `<leader>F` |
| `<leader>cr` | n | Rename |  | dropped, use `<F2>` |
| `<leader>ca` | n,x | Code Action |  | dropped, use `<F4>` |
| `<leader>cd` | n | Line Diagnostics |  | dropped, use `<leader>L` |
| `<leader>uh` | n | Toggle Inlay Hints |  | dropped, use `<leader>T` |
| `<leader>xX` | n | Buffer Diagnostics (Trouble) |  | dropped, use `<leader>t` |
| `<leader>cp` | n | Markdown Preview |  | dropped, use `<leader>up` |
| `gI` | n | Goto Implementation |  | dropped, use `gi` |
| `gy` | n | Goto T[y]pe Definition |  | dropped, use `gt` |
| `gd` | n | Goto Definition | Go to Definition | dropped (KoalaVim gd) |
| `gr` | n | References | Go to References | dropped (KoalaVim gr) |
| `gD` | n | Goto Declaration | Go to Declaration | dropped (KoalaVim gD) |
| `K` | n | Hover | Trigger hover | dropped (KoalaVim K) |
| `gD` (typescript,typescriptreact,javascript,javascriptreact) | n | Goto Source Definition |  | dropped (KoalaVim gD) |
| `gK` | n | Signature Help | Go up to an end of a function | dropped (KoalaVim `<c-l>` / vim default) |
| `]h` | n | Next Hunk |  | dropped, use `]c` |
| `[h` | n | Prev Hunk |  | dropped, use `[c` |
| `<leader>db` | n | Toggle Breakpoint |  | dropped, use `<F9>` |
| `<leader>dc` | n | Run/Continue |  | dropped, use `<F5>` |
| `<leader>di` | n | Step Into |  | dropped, use `<F11>` |
| `<leader>dO` | n | Step Over |  | dropped, use `<F10>` |
| `<leader>do` | n | Step Out |  | dropped, use `<F12>` |
| `<leader>dC` | n | Run to Cursor |  | dropped, use `<leader>rc` |
| `<leader>de` | n,x | Eval |  | dropped, use `<leader>k` |
| `<leader>dr` | n | Toggle REPL |  | dropped, use `<leader>rp` |
| `<leader>dt` | n | Terminate |  | dropped, use `<F6>` |
| `<leader>ss` | n | LSP Symbols |  | dropped, use `gs` |
| `<leader>sS` | n | LSP Workspace Symbols |  | dropped, use `<leader>fs` |
| `<leader>sb` | n | Buffer Lines |  | moved to `<leader>fl` |
| `<leader>sB` | n | Grep Open Buffers |  | moved to `<leader>fG` |
| `<leader>sp` | n | Search for Plugin Spec |  | moved to `<leader>fP` |
| `<leader>s"` | n | Registers |  | moved to `<leader>f"` |
| `<leader>s/` | n | Search History |  | moved to `<leader>f/` |
| `<leader>sa` | n | Autocmds |  | moved to `<leader>fa` |
| `<leader>sc` | n | Command History |  | moved to `<leader>f:` |
| `<leader>sC` | n | Commands |  | moved to `<leader>fC` |
| `<leader>sd` | n | Diagnostics |  | moved to `<leader>fd` |
| `<leader>sD` | n | Buffer Diagnostics |  | moved to `<leader>fD` |
| `<leader>sh` | n | Help Pages |  | moved to `<leader>fh` |
| `<leader>sH` | n | Highlights |  | moved to `<leader>fH` |
| `<leader>sj` | n | Jumps |  | moved to `<leader>fj` |
| `<leader>sk` | n | Keymaps |  | moved to `<leader>fk` |
| `<leader>sl` | n | Location List |  | moved to `<leader>fQ` |
| `<leader>sq` | n | Quickfix List |  | moved to `<leader>fq` |
| `<leader>sM` | n | Man Pages |  | moved to `<leader>fM` |
| `<leader>sm` | n | Marks |  | moved to `<leader>f'` |
| `<leader>su` | n | Undotree |  | moved to `<leader>fu` |
| `<leader>st` | n | Todo |  | moved to `<leader>ft` |
| `<leader>sT` | n | Todo/Fix/Fixme |  | moved to `<leader>fT` |
| `<leader>snl` | n | Noice Last Message |  | moved to `<leader>fNl` |
| `<leader>sna` | n | Noice All |  | moved to `<leader>fNa` |
| `<leader>snt` | n | Noice Picker |  | moved to `<leader>fNt` |
| `<leader>sg` | n | Grep (Root Dir) |  | dropped, use `<leader>fw` |
| `<leader>sG` | n | Grep (cwd) |  | dropped, use `<leader>fcdd` |
| `<leader>sw` | n,x | Visual selection or word (Root Dir) |  | dropped, use `<leader>fcw` |
| `<leader>sW` | n,x | Visual selection or word (cwd) |  | dropped, use `<leader>fcW` |
| `<leader>sR` | n | Resume |  | dropped, use `<leader>fr` |
| `<leader>si` | n | Icons |  | dropped, use `<leader>fi` |
| `<leader>snh` | n | Noice History |  | dropped, use `<leader>N` |
| `<leader>snd` | n | Dismiss All |  | dropped, use `<leader>un` |
| `<leader>sn` | n | +noice |  | dropped (group label) |
| `<leader>sr` | n,x | Search and Replace |  | dropped, use `<leader>fnr` |
| `<leader>fb` | n | Buffers | Browse open buffers | dropped (KoalaVim `<leader>fb`) |
| `<leader>ff` | n | Find Files | Find file | dropped (KoalaVim `<leader>ff`) |
| `<leader>fe` | n | Explorer |  | dropped (nvim-tree `<M-m>`) |
| `<leader>fE` | n | Explorer |  | dropped (nvim-tree `<M-M>`) |
| `<leader>bb` | n | Switch to Other Buffer |  | dropped, use `<leader><Tab>` |
| `<leader>bd` | n | Delete Buffer |  | dropped, use `<leader>qq` |
| `<leader>bo` | n | Delete Other Buffers |  | dropped, use `<leader>qa` |
| `<leader>dPt` (python) | n | Debug Method |  | moved to `<leader>rT` |
| `<leader>dPc` (python) | n | Debug Class |  | moved to `<leader>rC` |
| `<leader>dr` (rust) | n | Rust Debuggables |  | moved to `<leader>rd` |

### KoalaVim keys that lose to LazyVim anyway

Entries whose owner is pinned in both flavors (`win` in `contested.lua`).

| Key | Mode | Action | Key now does | Result |
| --- | --- | --- | --- | --- |
| `<leader>ud` | n | Toggle dim | Toggle Diagnostics | dropped, use `<leader>uD` |

### LazyVim key families (prefix rules)

Every key longer than the prefix is rewritten (explicit rows above take precedence).

| LazyVim keys under | Result |
| --- | --- |
| `<leader>dp*` | moved under `<leader>uP*` |
| `<leader>d*` | moved under `<leader>r*` |
| `<leader>c*` | moved under `<leader>v*` |
| `<leader>b*` | moved under `<leader>q*` |
| `<leader><tab>*` | dropped (KoalaVim tabpage keys) |
| `<leader>gh*` | dropped (KoalaVim `<leader>h*`) |

### Keys added

Keys LazyVim had that KoalaVim's layout would have lost.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>zz` | n | Lazy |
| `<leader>zl` | n | LazyVim Changelog |
| `<leader>zx` | n | LazyVim Extras |

## `lazyvim` flavor

LazyVim wins contested keys; KoalaVim's bindings are moved or dropped.

### KoalaVim keys moved or dropped

| Key | Mode | Action | Key now does | Result |
| --- | --- | --- | --- | --- |
| `<leader>l` | n | Cycle between lsp diagnostics mode | Lazy | moved to `<leader>uv` |
| `<leader>L` | n | show Problem | LazyVim Changelog | dropped, use `<leader>cd` |
| `<leader>qq` | n | Close current tab | Quit All | dropped, use `<leader>bd` |
| `<leader>,` | n,v | Previous tabpage | Buffers | dropped, use `<leader><tab>[` |
| `<leader>.` | n,v | Next tabpage | Toggle Scratch Buffer | dropped, use `<leader><tab>]` |
| `` <leader>` `` | n | Replace surround to \` | Switch to Other Buffer | dropped |
| `<leader>ud` | n | Toggle dim | Toggle Diagnostics | dropped, use `<leader>uD` |
| `<leader>fr` | n | Find resume | Recent | dropped, use `<leader>sR` |
| `<leader>gg` | n | diff_viewer | Lazygit | moved to `<leader>gV` |
| `<leader>gs` | n | Open Neogit | Git Status | moved to `<leader>gn` |
| `<leader>gd` | n | Git show diff | Git Diff (hunks) | moved to `<leader>gv` |
| `<leader>gD` | n | Git dirtyfiles | Git Diff (origin) | dropped, use `<leader>gs` |
| `<leader>gp` | n | Git push | GitHub Pull Requests (open) | moved to `<leader>gu` |
| `<leader>gP` | n | Git push (alias) | GitHub Pull Requests (all) | moved to `<leader>gU` |
| `<leader>gI` | n | Search Issues (Octo) | GitHub Issues (all) | moved to `<leader>gOI` |
| `<leader>gS` | n | Search (Octo) | Git Stash | moved to `<leader>gOS` |
| `<leader>gl` | n | List Repos (Octo) | Git Log | moved to `<leader>gOl` |
| `<leader>gr` | n | List PRs (Octo) |  | moved to `<leader>gOr` |
| `<leader>gR` | n | Search PRs (Octo) |  | moved to `<leader>gOR` |
| `<leader>gic` | n | Create Issue (Octo) |  | moved to `<leader>gOic` |
| `<leader>gil` | n | List Issues (Octo) |  | moved to `<leader>gOil` |
| `<leader>gh` | n | Git file History |  | dropped, use `<leader>gf` |
| `<C-k>` | i | Insert new line | Signature Help | dropped |
| `<C-s>` | n | Open Git Status | Save File | dropped, use `<leader>gn` |
| `<M-j>` | n | Jump to next git hunk | Move Down | dropped, use `]h` |
| `<M-k>` | n | Jump to previous git hunk | Move Up | dropped, use `[h` |
| `<C-Up>` | n | add above | Increase Window Height | moved to `<M-Up>` |
| `<C-Down>` | n | add below | Decrease Window Height | moved to `<M-Down>` |
| `<C-Left>` | n | Swap with left sibling | Decrease Window Width | moved to `<M-Left>` |
| `<C-Right>` | n | Swap with right sibling | Increase Window Width | moved to `<M-Right>` |
| `]c` | n | Jump to next git hunk | Next Class Start | dropped, use `]h` |
| `]C` | n | Jump to next git dirty file | Next Class End | moved to `]G` |
| `]]` | n,x,o | goto_next_start @class.outer | Next Reference | dropped, use `]c` |
| `]d` | n | Goto next breakpoint | Next Diagnostic | moved to `]r` |
| `]w` | n | Next diagnostic (warning) | Next Warning | dropped, use `]d` |
| `]e` | n | Next error | Next Error | dropped |
| `]g` | n | Next error |  | dropped, use `]e` |
| `[c` | n | Jump to previous git hunk | Prev Class Start | dropped, use `[h` |
| `[C` | n | Jump to previous git dirty file | Prev Class End | moved to `[G` |
| `[[` | n,x,o | goto_previous_start @class.outer | Prev Reference | dropped, use `[c` |
| `[d` | n | Goto prev breakpoint | Prev Diagnostic | moved to `[r` |
| `[w` | n | Prev diagnostic (warning) | Prev Warning | dropped, use `[d` |
| `[e` | n | Prev error | Prev Error | dropped |
| `[g` | n | Prev error |  | dropped, use `[e` |
| `<C-n>` | n | jump to Next occurrence |  | dropped, use `]]` |
| `<C-p>` | n | jump to Previous occurrence |  | dropped, use `[[` |
| `<Down>` | n,x | Down to scroll | Down | dropped |
| `<Up>` | n,x | Up to scroll | Up | dropped |
| `j` | n,x | Move down inside wrapped line | Down | dropped (LazyVim j) |
| `k` | n,x | Move up inside wrapped line | Up | dropped (LazyVim k) |
| `<C-w>` | n | window_resizer |  | dropped, use `<c-w><space>` |
| `<C-d>` | n | Scroll down in hover |  | dropped, use `<c-f>` |
| `<C-u>` | n | Scroll up in hover |  | dropped, use `<c-b>` |
| `<leader>e` | n | Edit markdown codeblocks | Explorer | moved to `<leader>cE` |
| `<leader>e` (go) | n | Golang: create if err |  | moved to `<leader>cI` |
| `<leader>c` | n | change without yanking |  | moved to `<leader>C` |
| `<leader>C` | n | change rest of line without yanking |  | dropped, use `<leader>C$` |
| `<leader>d` | n | delete without yanking |  | moved to `<leader>D` |
| `<leader>D` | n | delete rest of line without yanking |  | dropped, use `<leader>D$` |
| `<leader>b` | n | Build & deploy |  | moved to `<leader>rb` |
| `<leader>B` | n | Reset deploy |  | moved to `<leader>rB` |
| `<leader>s` | n | spell fixer |  | moved to `<leader>uZ` |
| `<leader><Tab>` | n | Go to last active tab |  | dropped, use `<leader>bb` |
| `<leader>fn` | x |  |  | moved to `<leader>fN` |
| `]b` | n,x,o | goto_next_start @block.outer | Next Buffer | moved to `]o` |
| `[b` | n,x,o | goto_previous_start @block.outer | Prev Buffer | moved to `[o` |
| `]B` | n,x,o | goto_next_end @block.outer | Move buffer next | moved to `]O` |
| `[B` | n,x,o | goto_previous_end @block.outer | Move buffer prev | moved to `[O` |
| `n` | n | Auto recenter after n | Next Search Result | dropped (LazyVim n) |
| `N` | n | Auto recenter after N | Prev Search Result | dropped (LazyVim N) |
| `<leader>F` | n,x | Format |  | dropped, use `<leader>cf` |
| `<F2>` | n | Rename symbols |  | dropped, use `<leader>cr` |
| `<F4>` | n | Code action |  | dropped, use `<leader>ca` |
| `<leader>T` | n | Toggle inlay-hints |  | dropped, use `<leader>uh` |
| `<leader>t` | n | Buffer Diagnostics (Trouble) |  | dropped, use `<leader>xX` |
| `<leader>up` | n | Markdown Preview |  | dropped, use `<leader>cp` |
| `gi` | n | Go to Implementation |  | dropped, use `gI` |
| `gt` | n | Go to Type |  | dropped, use `gy` |
| `gd` | n | Go to Definition | Goto Definition | dropped (LazyVim gd) |
| `gr` | n | Go to References | References | dropped (LazyVim gr) |
| `gD` | n | Go to Declaration | Goto Declaration | dropped (LazyVim gD) |
| `K` | n | Trigger hover | Hover | dropped (LazyVim K) |
| `gK` | n,x | Go up to an end of a function | Signature Help | dropped, use `[F` |
| `<leader>hs` | n,v | Stage Hunk |  | dropped, use `<leader>ghs` |
| `<leader>hr` | n,v | Reset Hunk |  | dropped, use `<leader>ghr` |
| `<leader>hS` | n | Stage Buffer |  | dropped, use `<leader>ghS` |
| `<leader>hu` | n | Undo Stage |  | dropped, use `<leader>ghu` |
| `<leader>hR` | n | Reset Buffer |  | dropped, use `<leader>ghR` |
| `<leader>hp` | n | Preview Hunk |  | dropped, use `<leader>ghp` |
| `<leader>hb` | n | Blame Line |  | dropped, use `<leader>ghb` |
| `ih` | o,x |  |  | dropped (LazyVim ih) |
| `<leader>fb` | n | Browse open buffers | Buffers | dropped (LazyVim `<leader>fb`) |
| `<leader>ff` | n | Find file | Find Files | dropped (LazyVim `<leader>ff`) |

### LazyVim keys that lose to KoalaVim anyway

Entries whose owner is pinned in both flavors (`win` in `contested.lua`).

| Key | Mode | Action | Key now does | Result |
| --- | --- | --- | --- | --- |
| `<C-h>` | n | Go to Left Window | Navigate | dropped (Navigator) |
| `<C-j>` | n | Go to Lower Window | Navigate | dropped (Navigator) |
| `<C-k>` | n | Go to Upper Window | Navigate | dropped (Navigator) |
| `<C-l>` | n | Go to Right Window | Navigate | dropped (Navigator) |

### KoalaVim key families (prefix rules)

Every key longer than the prefix is rewritten (explicit rows above take precedence).

| KoalaVim keys under | Result |
| --- | --- |
| `<leader>fc*` | moved under `<leader>fC*` |
| `<leader>fn*` | moved under `<leader>fN*` |

### Keys added

KoalaVim features that need a key in LazyVim's layout.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>e` | n | Explorer (nvim-tree) |
| `<leader>E` | n | Explorer (nvim-tree, locate file) |
