-- Run from the repository root with: nvim --headless -u NONE -l dev/test-ai-zoom.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local state, requested, zooms
zooms = {}
package.loaded['KoalaVim.health'] = { error = error }
package.loaded['sidekick.cli.state'] = {
	get = function()
		return { state }
	end,
	with = function(cb, opts)
		requested = opts
		cb(state)
	end,
}
local general = require('KoalaVim.utils.ai.general')
general.with_default_tool = function(action)
	action({ name = 'claude' })
end
general.get_default_tool = function()
	return 'claude'
end
state =
	{ session = {
		backend = 'herdr',
		zoom = function(_, enabled)
			zooms[#zooms + 1] = { enabled = enabled }
		end,
	} }
local modes = require('KoalaVim.utils.modes')
modes.load('ai', '')
assert(requested.attach and requested.show and requested.focus)
assert(requested.filter.name == 'claude')
assert(#zooms == 1 and zooms[1].enabled == true)
modes.load('ai', '')
assert(#zooms == 2 and zooms[2].enabled == true)
general.zoom_sidekick()
assert(#zooms == 3 and zooms[3].enabled == nil)
general.toggle_max()
assert(#zooms == 4 and zooms[4].enabled == nil)
assert(#vim.api.nvim_list_tabpages() == 1)
print('AI mode maximizes attached native panes; zoom and max toggles route to Herdr')

state = { session = { backend = 'terminal' }, terminal = { win = vim.api.nvim_get_current_win() } }
assert(general.zoom_herdr(state) == false)
modes.load('ai', '')
assert(vim.wait(1000, function()
	return #vim.api.nvim_list_tabpages() == 2
end, 10))
general.zoom_sidekick(state, true)
assert(#vim.api.nvim_list_tabpages() == 2)
general.zoom_sidekick(state)
assert(#vim.api.nvim_list_tabpages() == 1)
print('AI mode also maximizes existing embedded terminals and restores their tab layout')
