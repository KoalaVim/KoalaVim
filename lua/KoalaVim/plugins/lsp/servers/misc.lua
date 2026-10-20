-- Servers that I didn't specially configured due lack of use or lack of configurition needed
return {
	{
		'neovim/nvim-lspconfig',
		opts = {
			servers = {
				bashls = {},
				vimls = {},
			},
		},
	},
}
