## Context

KoalaVim binds `<C-h/j/k/l>` in normal and terminal mode to `NavigatorLeft/Down/Up/Right` (`lua/KoalaVim/plugins/editor.lua`), and sidekick.nvim's CLI window reuses the same commands for its `nav_*` keys (`lua/KoalaVim/plugins/ai.lua`). Navigator.nvim owns the interesting part of that behaviour: it runs `wincmd <dir>`, compares the window id before and after, and only signals the multiplexer when the window did not change (i.e. the cursor was already at the edge). It also tracks a `last_pane` flag so a second press keeps travelling outward, and clears it on `WinEnter`.

Navigator ships three mux backends under `lua/Navigator/mux/`: `tmux`, `wezterm`, and `vi` (a no-op base class used when nothing is detected). `Navigator.navigate.load_mux()` probes tmux, then WezTerm, then falls back to `vi`. There is no Zellij backend, so inside a Zellij session `<C-hjkl>` dies at the edge of the Neovim layout.

A working implementation already exists outside this repo at `configs/nvim-atom/lua/atom/zellij.lua`. It re-implements the edge detection itself and shells out to `zellij action` asynchronously via `vim.system`, warning on a non-zero exit. It uses `move-focus-or-tab` for horizontal moves, mirroring the `MoveFocusOrTab` bindings in that author's `configs/zellij/config.kdl`; KoalaVim deliberately does not (see Decision 3).

The Zellij half of the handoff — Zellij must be in locked mode for `<C-hjkl>` to reach Neovim at all, which `zellij-autolock` arranges whenever the focused pane runs `nvim` — lives in the user's dotfiles and is a prerequisite, not part of this change.

Constraint: KoalaVim is a shared distribution. Zellij support must be additive and inert for users on tmux, WezTerm, or no multiplexer.

## Goals / Non-Goals

**Goals:**

- `<C-h/j/k/l>` hands focus to the neighbouring Zellij pane when the cursor is at the edge of Neovim's window layout.
- Reuse Navigator's edge detection, `last_pane` follow-through, `WinEnter` reset, and existing keymaps instead of re-implementing them.
- Preserve tmux, WezTerm, and no-multiplexer behaviour exactly.
- Correct behaviour when Zellij is nested inside another multiplexer.
- A failed `zellij` invocation is visible, not swallowed.

**Non-Goals:**

- Zellij-side configuration (`config.kdl` keybindings, `zellij-autolock`). Documented as a prerequisite only.
- Upstreaming the backend to numToStr/Navigator.nvim. Worth doing later; out of scope here.
- Zoom/fullscreen awareness (see Decision 5).
- User-facing configuration for the tab-fallthrough behaviour (see Decision 3).
- New keymaps or changes to existing ones.

## Decisions

### 1. Implement Navigator's mux interface rather than replacing Navigator

Add `lua/KoalaVim/utils/plugins/navigator_zellij.lua` — a class extending `require('Navigator.mux.vi')` with `new()`, `navigate(direction)`, and `zoomed()`, following the shape of the upstream `wezterm` backend. Navigator documents this as its custom-multiplexer extension point.

*Alternative considered:* port `atom/zellij.lua` verbatim and drop Navigator.nvim. Rejected — it duplicates edge detection and `last_pane` follow-through, and would remove tmux/WezTerm support that other KoalaVim users depend on.

*Coupling risk accepted:* the backend depends on Navigator's internal module path `Navigator.mux.vi`. It is the documented extension point, and Navigator is pinned in `lazy-lock.json`.

### 2. Select the backend explicitly by `$ZELLIJ`, do not touch `load_mux()`

The Navigator plugin spec resolves `opts.mux` in its `config` function: if `vim.env.ZELLIJ` is set, `pcall` the Zellij backend's constructor and pass the instance; otherwise pass `'auto'` and let Navigator probe tmux → WezTerm → `vi` as it does today.

This is required for correctness, not just convenience: Zellij nested inside WezTerm sets both `$ZELLIJ` and `TERM_PROGRAM=WezTerm`, and Navigator's `load_mux()` would pick WezTerm. Zellij is the innermost multiplexer and owns the pane Neovim sits in, so it must win. Resolving at `config` time also keeps the decision in one readable place instead of monkey-patching detection order.

The `pcall` keeps a constructor failure non-fatal: it degrades to `'auto'`, matching today's behaviour rather than breaking navigation entirely.

*Alternative considered:* `assert(vim.env.ZELLIJ)` inside `new()` and letting a patched `load_mux()` probe Zellij first. Rejected — patching upstream detection order is more fragile than deciding at the call site. The `assert` in `new()` is still kept as a guard, so the constructor is honest when called directly.

### 3. `move-focus` in every direction — pane-scoped, never crossing tabs

The direction table maps all of `h`/`j`/`k`/`l` to `move-focus`.

The source module uses `move-focus-or-tab` for `h`/`l`, so horizontal travel falls through to the adjacent tab at the session edge. That mirrors its author's `config.kdl`, but it is the wrong default for KoalaVim: both existing backends are strictly pane-scoped and stop at the edge — tmux uses `select-pane -LRUD` and wezterm `activate-pane-direction`, neither of which switches window or tab. Adopting the fallthrough would make zellij the only backend where `<C-h>` can teleport you to a different tab. Consistency across backends wins over fidelity to the source module.

Left as a module-level constant rather than a user option: adding a config-scheme knob for a five-line table is not worth the surface area, and no second consumer exists yet.

### 4. `direction = 'p'` maps to `focus-previous-pane`

Navigator's `Direction` alias includes `p` (previous pane), reachable via `NavigatorPrevious`. KoalaVim does not bind it, but the backend must not `nil`-index if something calls it. `p` maps to `zellij action focus-previous-pane`, which takes no direction argument — so the command table stores an argument list per direction rather than a fixed `{action, direction}` pair.

### 5. `zoomed()` returns `false`

Navigator only calls `zoomed()` when `disable_on_zoom` is true, and KoalaVim sets it to `false`. A real answer would need a synchronous `zellij action list-panes` parse on every keypress; not worth it for a code path that is never taken. Inheriting `vi`'s `false` is sufficient, and the reasoning is worth a comment so the omission does not read as an oversight.

### 6. Async `vim.system`, warn on non-zero exit

Spawn `{ 'zellij', 'action', ... }` through `vim.system` with a completion callback; on a non-zero exit, `vim.schedule` a `vim.log.levels.WARN` notification carrying the collapsed stderr. Navigator's own backends use blocking `io.popen`, which stalls the UI on every edge press — no reason to inherit that. `navigate()` still returns `self` to honour the interface contract; Navigator ignores the return value.

Note that `auto_save` is unset in KoalaVim's Navigator opts, so nothing in Navigator's post-handoff path depends on the `zellij` call having completed. Async is safe here.

### 7. Verification is manual

There is no test harness for keymaps or multiplexer handoff in this repo, and the behaviour is inherently interactive. Verification is a documented manual checklist (inside Zellij, outside Zellij, nested under WezTerm, forced-failure notification) plus `stylua --check` and a `:lua` load check.

## Risks / Trade-offs

- **Navigator's internal `Navigator.mux.vi` path changes upstream** → the `pcall` around the constructor degrades to `mux = 'auto'` instead of breaking navigation; Navigator is version-pinned in `lazy-lock.json`, so a break can only arrive with a deliberate update.
- **`zellij` binary missing from `PATH` while `$ZELLIJ` is set** → `vim.system` fails and the error surfaces as the same warning notification; Neovim-internal navigation is unaffected.
- **Async fire-and-forget means rapid `<C-h>` presses could race** → each press is an independent focus command and Zellij serialises them; the worst case is over-travel, which is also what tmux users get today.
- **Zellij not in locked mode** → `<C-hjkl>` never reaches Neovim, so this code appears dead. Not fixable from Neovim; called out explicitly in the docs so the failure is diagnosable.
- **Zoom is ignored** → navigating out of a zoomed Zellij pane un-zooms rather than being suppressed. Accepted; `disable_on_zoom` is `false` today, so this matches current tmux/WezTerm behaviour in this config.
- **This repo is checked out twice** (`~/.local/share/kvim-envs/main/lazy/KoalaVim` and `~/workspaces/personal/koala/KoalaVim`, both on the same commit). Implementation lands in the OpenSpec planning root; the other clone picks it up via `git`, not by a second manual edit.

## Migration Plan

Additive; no migration. Rollback is reverting the two edits — `mux = 'auto'` restores today's behaviour, and the new file becomes dead code.

## Open Questions

- Should the backend be contributed upstream to numToStr/Navigator.nvim so `load_mux()` probes Zellij natively? Deferred; local first, upstream once it has been used in anger.
