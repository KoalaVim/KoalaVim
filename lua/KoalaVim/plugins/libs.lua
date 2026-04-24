return {
	-- library used by other plugins
	-- Lua utility library: async, path, job helpers used across the ecosystem
	{ 'nvim-lua/plenary.nvim', lazy = true },
	-- makes some plugins dot-repeatable like leap
	-- Enables '.' repeat for plugin-provided operators (leap, surround, etc.)
	{ 'tpope/vim-repeat', event = 'VeryLazy' },
}
