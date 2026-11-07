vim.opt.rtp:prepend(vim.fn.getcwd())
local state, command, sent
package.loaded['sidekick.cli.state'] = {
	get = function()
		return state and { state } or {}
	end,
	with = function(cb)
		cb(state)
	end,
}
package.loaded['sidekick.util'] = {
	exec = function(cmd)
		command = cmd
	end,
}
local general = require('KoalaVim.utils.ai.general')
local original = vim.api.nvim_chan_send
vim.api.nvim_chan_send = function(chan, text)
	sent = { chan, text }
end
state = { session = { backend = 'herdr', herdr_pane_id = 'agent' } }
general.send_editor_key()
assert(vim.deep_equal(command, { 'herdr', 'pane', 'send-keys', 'agent', 'ctrl+g' }))
assert(sent == nil)
state = { session = { backend = 'terminal' }, terminal = { buf = 0 }, tool = { name = 'unknown' } }
general.send_editor_key()
assert(sent[2] == '\7')
vim.api.nvim_chan_send = original
print('Native pane and embedded terminal editor-key tests passed')

local editor_key
for _, plugin in ipairs(require('KoalaVim.plugins.ai')) do
	for _, key in ipairs(plugin.keys or {}) do
		if key[1] == '<C-e>' and key.mode == 'n' and not key.ft then
			editor_key = key[2]
		end
	end
end
assert(editor_key)
state = { session = { backend = 'herdr', herdr_pane_id = 'agent' } }
command = nil
editor_key()
assert(vim.deep_equal(command, { 'herdr', 'pane', 'send-keys', 'agent', 'ctrl+g' }))
state = nil
command = nil
vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.tbl_map(tostring, vim.fn.range(1, 100)))
vim.api.nvim_win_set_cursor(0, { 20, 0 })
vim.cmd('normal! zt')
local topline = vim.fn.winsaveview().topline
editor_key()
assert(command == nil)
assert(vim.fn.winsaveview().topline == topline + 1)
print('Normal-mode Ctrl+E opens the mux proxy editor and preserves scrolling without an attached agent')
