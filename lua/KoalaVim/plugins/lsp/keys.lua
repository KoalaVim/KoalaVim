-- Applies the contested-keys table to LazyVim's LSP keymaps, see `KoalaVim.keymaps.remap`.
--
-- Must be the LAST `opts` fragment of nvim-lspconfig: it rewrites the `keys` of every server in `opts.servers`, so all
-- the server fragments (LazyVim's, its extras and KoalaVim's `plugins/lsp/servers/*`) have to be merged before it.
-- lazy.nvim imports the files of a module sorted by name and `KoalaVim.plugins.lsp.servers` is imported before
-- `KoalaVim.plugins.lsp` (see `spec.lua`): `diagnostics`, `format` and `general` < `keys`.
-- Don't add an `init` here, lazy.nvim doesn't merge it and `general.lua` owns it.
local M = {}

table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = function(_, opts)
		require('KoalaVim.keymaps.remap').servers(opts.servers)
	end,
})

return M
