-- Run from the repository root with: nvim --headless -u NONE -l dev/test-editor-zoom.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local general = require('KoalaVim.utils.ai.general')
local calls, zoomed
package.loaded['sidekick.util'] = {
	exec = function(cmd)
		if cmd[3] == 'layout' then
			return true, vim.json.encode({ result = { layout = { zoomed = zoomed } } })
		end
		calls[#calls + 1] = { cmd[3], cmd[4], cmd[5] }
		return true
	end,
}
local function stub_upvalue(name, replacement)
	for i = 1, 100 do
		local found = debug.getupvalue(general.open_editor_file, i)
		if not found then
			break
		end
		if found == name then
			debug.setupvalue(general.open_editor_file, i, replacement)
			return
		end
	end
	error('Missing upvalue: ' .. name)
end
stub_upvalue('herdr_focus_pane', function(pane)
	calls[#calls + 1] = { 'focus', pane }
end)
stub_upvalue('open_prompt_win', function(buf)
	vim.cmd.vsplit()
	vim.api.nvim_win_set_buf(0, buf)
	return vim.api.nvim_get_current_win()
end)
stub_upvalue('setup_prompt_split', function() end)
stub_upvalue('signal_editor_pipe', function()
	calls[#calls + 1] = { 'signal' }
end)
vim.env.HERDR_PANE_ID = 'editor'
for _, initial_zoom in ipairs({ true, false }) do
	calls, zoomed = {}, initial_zoom
	local file = vim.fn.tempname()
	vim.fn.writefile({ 'prompt' }, file)
	general.open_editor_file(file, 'test-pipe', 'agent')
	assert(vim.wait(1000, function()
		return vim.api.nvim_get_current_buf() == vim.fn.bufnr(file)
	end, 10))
	if initial_zoom then
		assert(vim.deep_equal(calls, { { 'zoom', 'agent', '--off' }, { 'focus', 'editor' } }))
	else
		assert(vim.deep_equal(calls, { { 'focus', 'editor' } }))
	end
	vim.api.nvim_win_close(0, true)
	if initial_zoom then
		assert(vim.deep_equal(calls, {
			{ 'zoom', 'agent', '--off' },
			{ 'focus', 'editor' },
			{ 'signal' },
			{ 'zoom', 'agent', '--on' },
		}))
	else
		assert(vim.deep_equal(calls, { { 'focus', 'editor' }, { 'signal' }, { 'focus', 'agent' } }))
	end
	vim.fn.delete(file)
end
print('Editor round-trip unzooms before focusing Neovim, restores agent zoom, and preserves unzoomed layouts')

-- A proxy opened from Alpha replaces it and can be closed as the last window.
calls, zoomed = {}, false
_G.CLOSE_KOALA_DASHBOARD = function() end
vim.bo.filetype = 'alpha'
vim.bo.bufhidden = 'wipe'
local dashboard_buf = vim.api.nvim_get_current_buf()
local file = vim.fn.tempname()
vim.fn.writefile({ 'original' }, file)
general.open_editor_file(file, 'last-window-pipe', 'agent')
assert(vim.wait(1000, function()
	return vim.api.nvim_get_current_buf() == vim.fn.bufnr(file)
end, 10))
assert(not vim.api.nvim_buf_is_valid(dashboard_buf))
assert(#vim.api.nvim_list_wins() == 1)
assert(vim.b.koala_editor_proxy)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'edited' })
require('KoalaVim.utils.splits').close()
assert(#vim.api.nvim_list_wins() == 1)
assert(not vim.b.koala_editor_proxy)
assert(vim.deep_equal(vim.fn.readfile(file), { 'edited' }))
assert(vim.deep_equal(calls, { { 'focus', 'editor' }, { 'signal' }, { 'focus', 'agent' } }))
vim.fn.delete(file)
print('Proxy replaces Alpha; closing its last window saves the edit, releases the agent, and keeps Neovim open')
