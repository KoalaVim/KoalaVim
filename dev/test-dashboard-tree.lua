-- Run from the repository root with: nvim --headless -u NONE -l dev/test-dashboard-tree.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:prepend(vim.fn.fnamemodify('../alpha-nvim', ':p'))
vim.opt.rtp:prepend(vim.fn.fnamemodify('../nvim-tree.lua', ':p'))
package.loaded['KoalaVim.conf'] = {}
package.loaded['KoalaVim.utils.update_checker'] = { check = function() end }
package.loaded['KoalaVim'] = { conf = { autocmds = {} } }
dofile('lua/KoalaVim/config_lazy/autocmds/misc.lua')
require('nvim-tree').setup({})
local spec
for _, plugin in ipairs(require('KoalaVim.plugins.ui')) do
	if plugin[1] == 'KoalaVim/alpha-nvim' then
		spec = plugin
	end
end
local dashboard = spec.opts()
require('alpha').setup(dashboard.opts)
require('alpha').start(false)
local alpha_buf = vim.api.nvim_get_current_buf()
local button
for _, b in ipairs(dashboard.section.buttons.val) do
	if b.opts.shortcut == 'm' then
		button = b
	end
end
assert(button)
button.on_press()
assert(#vim.api.nvim_tabpage_list_wins(0) == 1)
assert(vim.bo.filetype == 'NvimTree')
assert(not vim.api.nvim_buf_is_valid(alpha_buf))
print('Dashboard file-tree action leaves one tree window and removes Alpha')

-- Repeat with an existing tree: the dashboard window must close while the tree stays.
vim.cmd.vsplit()
vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))
require('alpha').start(false)
local second_alpha = vim.api.nvim_get_current_buf()
button.on_press()
assert(#vim.api.nvim_tabpage_list_wins(0) == 1)
assert(vim.bo.filetype == 'NvimTree')
assert(not vim.api.nvim_buf_is_valid(second_alpha))
print('Existing tree also stays open with KoalaVim auto-quit enabled')
