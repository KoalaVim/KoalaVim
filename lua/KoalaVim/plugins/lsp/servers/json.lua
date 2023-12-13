local M = {}

LSP_SERVERS['jsonls'] = {
	lazy = true, -- For SchemaStore.nvim
}

LSP_SERVERS['yamlls'] = {
	lazy = true, -- For SchemaStore.nvim
}

table.insert(M, {
	'b0o/SchemaStore.nvim',
	ft = { 'yaml', 'yaml.docker-compose', 'json', 'jsonc' },
	config = function()
		require('lspconfig').jsonls.setup({
			capabilities = LSP_CAPS,
			on_attach = LSP_ON_ATTACH,
			settings = {
				json = {
					schemas = require('schemastore').json.schemas(),
					validate = { enable = true },
				},
			},
		})

		require('lspconfig').yamlls.setup({
			capabilities = LSP_CAPS,
			on_attach = LSP_ON_ATTACH,
			settings = {
				yaml = {
					schemaStore = {
						-- You must disable built-in schemaStore support if you want to use
						-- this plugin and its advanced options like `ignore`.
						enable = false,
						-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
						url = '',
					},
					schemas = require('schemastore').yaml.schemas(),
				},
			},
		})
	end,
})

return M
