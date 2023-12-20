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
		-- Add kvim.jsonc scheme
		local json_schemes = require('schemastore').json.schemas()
		table.insert(json_schemes, require('KoalaVim.conf').get_scheme())

		require('lspconfig').jsonls.setup({
			capabilities = LSP_CAPS,
			on_attach = LSP_ON_ATTACH,
			settings = {
				json = {
					schemas = json_schemes,
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
