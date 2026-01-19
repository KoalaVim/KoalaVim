local M = {}

-- FIXME: vim.lsp: jsonls and yamlls used to be lazy setup. needs to see if requires migration to new api
LSP_SERVERS['jsonls'] = {
}

LSP_SERVERS['yamlls'] = {
}

table.insert(M, {
	'b0o/SchemaStore.nvim',
	ft = { 'yaml', 'yaml.docker-compose', 'json', 'jsonc' },
	config = function()
		-- Add kvim.jsonc scheme
		local json_schemes = require('schemastore').json.schemas()
		table.insert(json_schemes, require('KoalaVim.conf').get_scheme())

		vim.lsp.config.jsonls = {
			capabilities = LSP_CAPS,
			on_attach = LSP_ON_ATTACH,
			on_init = LSP_ON_INIT,
			settings = {
				json = {
					schemas = json_schemes,
					validate = { enable = true },
				},
			},
		}
		vim.lsp.enable('jsonls')

		vim.lsp.config.yamlls = {
			capabilities = LSP_CAPS,
			on_attach = LSP_ON_ATTACH,
			on_init = LSP_ON_INIT,
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
		}
		vim.lsp.enable('yamlls')
	end,
})

return M
