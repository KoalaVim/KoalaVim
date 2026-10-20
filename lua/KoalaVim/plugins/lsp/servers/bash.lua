-- Formatter for bash (shfmt is also in LazyVim's default mason tools)
return {
	{
		'stevearc/conform.nvim',
		opts = { formatters_by_ft = { bash = { 'shfmt' } } },
	},
	{
		'mason-org/mason.nvim',
		opts = { ensure_installed = { 'shfmt' } },
	},
}
