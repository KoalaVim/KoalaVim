# Address FIXME comments across the codebase

## Summary

There are **31 FIXME comments** scattered across the codebase that need attention. This issue tracks all of them, grouped by category.

---

### Sessions (`lua/KoalaVim/plugins/sessions.lua`)

- [ ] **Line 109** — `nvim_set_current_dir` sometimes crashes nvim when loading session from argv

### Editor (`lua/KoalaVim/plugins/editor.lua`)

- [ ] **Line 27** — Disable autosave on codediff (for conflicts)
- [ ] **Line 692** — Go over `snacks.nvim` and replace/add functionality

### Git (`lua/KoalaVim/plugins/git.lua`)

- [ ] **Line 224** — Support non-ofirkai themes in codediff floating window
- [ ] **Line 305** — Test codediff conflict resolution keymaps
- [ ] **Line 335** — Support custom keymaps in codediff to clean up workaround code
- [ ] **Line 390** — Migrate old diffview keymaps to new format
- [ ] **Line 481** — Hook to diffview create/close to clear autocmds
- [ ] **Line 763** — Add `gh auth refresh -s read:project` to README

### AI / Sidekick (`lua/KoalaVim/plugins/ai.lua`)

- [ ] **Line 26** — `get_prompt()` should only apply for cursor
- [ ] **Line 84** — Sidekick buffer manipulation may need to be cursor-only
- [ ] **Line 134** — Show hidden files in sidekick file picker
- [ ] **Lines 208, 216, 226, 236, 246, 256** — Multiple keymaps should only apply in cursor (6 occurrences)
- [ ] **Line 273** — Enable 'nes' (nested completion)
- [ ] **Line 287** — Default sidekick agent should come from koalaconfig

### UI (`lua/KoalaVim/plugins/ui.lua`)

- [ ] **Line 71** — Show scopes of dicts in indent-blankline
- [ ] **Lines 486, 500** — Migrate which-key registrations to new format
- [ ] **Line 719** — Fix vimade tinting color issues

### LSP Servers (`lua/KoalaVim/plugins/lsp/servers/`)

- [ ] **rust.lua:51** — Add bacon integration from LazyVim
- [ ] **lua_ls.lua:5** — Lazy loading lazydev.nvim doesn't work reliably
- [ ] **json.lua:3** — Verify jsonls/yamlls migration to new LSP API
- [ ] **go.lua:9** — Enable go.nvim
- [ ] **typescript.lua:29** — Enable eslint_d none-ls source

### LSP General (`lua/KoalaVim/plugins/lsp/general.lua`)

- [ ] **Line 48** — Re-visit LSP capabilities, on_attach and on_init
- [ ] **Line 377** — Remove `conform` branch pin after merging format-on-leave to master

### Utilities

- [ ] **utils/git.lua:61** — Optimize `jump_to_git_dirty_file()`
- [ ] **utils/misc.lua:15** — Move restart/session logic to possession.nvim
- [ ] **utils/lsp.lua:107** — Support disabling all formatters from config

---

### Priority Suggestions

**High** — Session crash (sessions.lua:109), LSP setup review (general.lua:48), lazy loading (lua_ls.lua:5)

**Medium** — Migration tasks (json.lua, git.lua keymaps, which-key), feature enablement (go.lua, typescript.lua)

**Low** — Optimizations (git utils), documentation (README auth), config defaults (ai.lua:287)
