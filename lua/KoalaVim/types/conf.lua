---@meta
-- Generated from config_scheme.jsonc — do not edit manually.
-- Run: nvim -l scripts/gen_conf_types.lua

---@class KoalaVim.Conf
---@field ai KoalaVim.Conf.ai
---@field autocmds KoalaVim.Conf.autocmds
---@field editor KoalaVim.Conf.editor
---@field lsp KoalaVim.Conf.lsp
---@field plugins KoalaVim.Conf.plugins
---@field ui KoalaVim.Conf.ui

---@class KoalaVim.Conf.ai
---@field auto_edit_prompt KoalaVim.Conf.ai.auto_edit_prompt
---@field default_tool string?
---@field edit_prompt_layout string
---@field inline_float KoalaVim.Conf.ai.inline_float
---@field pi_prompt_anchor string?

---@class KoalaVim.Conf.ai.auto_edit_prompt
---@field count number
---@field enabled boolean
---@field render_delay_ms number
---@field window_ms number

---@class KoalaVim.Conf.ai.inline_float
---@field min_height number
---@field min_width number

---@class KoalaVim.Conf.autocmds
---@field absolute_lines boolean
---@field half_screen KoalaVim.Conf.autocmds.half_screen

---@class KoalaVim.Conf.autocmds.half_screen
---@field full_screen_width number?

---@class KoalaVim.Conf.editor
---@field indent KoalaVim.Conf.editor.indent

---@class KoalaVim.Conf.editor.indent
---@field tab_size KoalaVim.Conf.editor.indent.tab_size

---@class KoalaVim.Conf.editor.indent.tab_size
---@field max number
---@field min number

---@class KoalaVim.Conf.lsp
---@field autoformat KoalaVim.Conf.lsp.autoformat
---@field format KoalaVim.Conf.lsp.format
---@field tsgo KoalaVim.Conf.lsp.tsgo
---@field vtsls KoalaVim.Conf.lsp.vtsls

---@class KoalaVim.Conf.lsp.autoformat
---@field blacklist string[]
---@field blacklist_ft string[]

---@class KoalaVim.Conf.lsp.format
---@field blacklist string[]
---@field blacklist_ft string[]

---@class KoalaVim.Conf.lsp.tsgo
---@field enabled boolean

---@class KoalaVim.Conf.lsp.vtsls
---@field max_memory number?

---@class KoalaVim.Conf.plugins
---@field fff KoalaVim.Conf.plugins.fff
---@field open_jira KoalaVim.Conf.plugins.open_jira

---@class KoalaVim.Conf.plugins.fff
---@field additional_ignore_patterns string[]

---@class KoalaVim.Conf.plugins.open_jira
---@field jira_url string?

---@class KoalaVim.Conf.ui
---@field statusline KoalaVim.Conf.ui.statusline

---@class KoalaVim.Conf.ui.statusline
---@field icons_only boolean
