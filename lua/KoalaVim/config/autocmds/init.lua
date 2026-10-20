-- Aggregates all KoalaVim autocmds modules in this directory.
-- Loaded on LazyVim's `LazyVimAutocmdsDefaults` event (see `KoalaVim.init()`)
local dir = vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2))

return require('KoalaVim.utils.require_dir').require_abs(dir, 'KoalaVim.config.autocmds', {
	skip = function(module)
		return module == 'init'
	end,
})
