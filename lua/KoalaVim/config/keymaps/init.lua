-- Aggregates all KoalaVim keymaps modules in this directory.
-- Loaded on LazyVim's `LazyVimKeymapsDefaults` event (see `KoalaVim.init()`)
local dir = vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2))

return require('KoalaVim.utils.require_dir').require_abs(dir, 'KoalaVim.config.keymaps', {
	skip = function(module)
		return module == 'init'
	end,
})
