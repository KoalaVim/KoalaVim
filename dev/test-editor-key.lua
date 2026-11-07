vim.opt.rtp:prepend(vim.fn.getcwd())
local state, command, sent
package.loaded['sidekick.cli.state'] = {
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
