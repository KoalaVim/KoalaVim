return {
	{ 'LazyVim/LazyVim', import = 'lazyvim.plugins', opts = { colorscheme = 'ofirkai', news = { lazyvim = true } } },

	-- LazyVim extras KoalaVim depends on (must stay between `lazyvim.plugins` and `KoalaVim.plugins`)
	-- { import = 'lazyvim.plugins.extras.<category>.<name>' },

	-- Debugging and reference highlighting (KoalaVim layers its ui/adapters on top)
	{ import = 'lazyvim.plugins.extras.dap.core' },
	{ import = 'lazyvim.plugins.extras.editor.illuminate' },

	-- Language packs (LSP, formatter, linter, treesitter and debugger per language)
	{ import = 'lazyvim.plugins.extras.lang.clangd' },
	{ import = 'lazyvim.plugins.extras.lang.cmake' },
	{ import = 'lazyvim.plugins.extras.lang.docker' },
	{ import = 'lazyvim.plugins.extras.lang.go' },
	{ import = 'lazyvim.plugins.extras.lang.json' },
	{ import = 'lazyvim.plugins.extras.lang.markdown' },
	{ import = 'lazyvim.plugins.extras.lang.python' },
	{ import = 'lazyvim.plugins.extras.lang.rust' },
	{ import = 'lazyvim.plugins.extras.lang.typescript' },
	{ import = 'lazyvim.plugins.extras.lang.zig' },

	{ 'KoalaVim/KoalaVim', import = 'KoalaVim.plugins' },

	{ import = 'KoalaVim.plugins.hydra/hydras/helpers' },
	{ import = 'KoalaVim.plugins.hydra/hydras' },
	{ import = 'KoalaVim.plugins.hydra' },
	{ import = 'KoalaVim.plugins.lsp.servers' },
	{ import = 'KoalaVim.plugins.lsp' },
}
