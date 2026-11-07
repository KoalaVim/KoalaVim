-- Run from the repository root with: nvim --headless -u NONE -l dev/test-ai-zoom.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local state, requested, zooms
local eligible = true
local created = true
local focused = 0
zooms = {}
package.loaded['KoalaVim.health'] = { error = error }
package.loaded['sidekick.cli.state'] = {
	get = function()
		return { state }
	end,
	with = function(cb, opts)
		requested = opts
		cb(state, true, created)
	end,
}
local general = require('KoalaVim.utils.ai.general')
general.with_default_tool = function(action)
	action({ name = 'claude' })
end
general.get_default_tool = function()
	return 'claude'
end
state = {
	session = {
		backend = 'herdr',
		focus = function()
			focused = focused + 1
		end,
		zoom = function(_, enabled)
			if not eligible then
				return false
			end
			zooms[#zooms + 1] = { enabled = enabled }
			return true
		end,
	},
}
local modes = require('KoalaVim.utils.modes')
modes.load('ai', '')
assert(requested.attach and requested.show and requested.focus == false)
assert(focused == 1)
assert(requested.filter.name == 'claude')
assert(#zooms == 1 and zooms[1].enabled == true)
created = false
modes.load('ai', '')
assert(#zooms == 1)
assert(focused == 1)
created = true
modes.load('ai', '')
assert(#zooms == 2 and zooms[2].enabled == true)
assert(focused == 2)
general.zoom_sidekick()
assert(#zooms == 3 and zooms[3].enabled == nil)
general.toggle_max()
assert(#zooms == 4 and zooms[4].enabled == nil)
assert(#vim.api.nvim_list_tabpages() == 1)
print('AI mode zooms only newly created native panes; reattachment preserves zoom and manual toggles work')

eligible = false
assert(general.zoom_herdr() == false)
modes.load('ai', '')
general.zoom_sidekick()
assert(#zooms == 4)
assert(#vim.api.nvim_list_tabpages() == 1)
print('Ineligible native layouts skip AI zoom and allow normal Alt-z fallback')

state = {
	session = { backend = 'terminal' },
	terminal = {
		win = vim.api.nvim_get_current_win(),
		is_running = function()
			return true
		end,
		focus = function() end,
	},
}
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
