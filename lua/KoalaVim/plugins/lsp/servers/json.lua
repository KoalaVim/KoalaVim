local M = {}

-- jsonls and SchemaStore come from LazyVim's json extra
table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = function(_, opts)
		-- The extra's `before_init` appends the SchemaStore schemas to this list
		opts.servers.jsonls = vim.tbl_deep_extend('force', opts.servers.jsonls or {}, {
			settings = {
				json = {
					schemas = { require('KoalaVim.conf').get_scheme() },
				},
			},
		})

		opts.servers.yamlls = vim.tbl_deep_extend('force', opts.servers.yamlls or {}, {
			-- lazy-load schemastore when needed
			before_init = function(_, new_config)
				new_config.settings.yaml.schemas = vim.tbl_deep_extend(
					'force',
					new_config.settings.yaml.schemas or {},
					require('schemastore').yaml.schemas()
				)
			end,
			settings = {
				yaml = {
					schemaStore = {
						-- You must disable built-in schemaStore support if you want to use
						-- this plugin and its advanced options like `ignore`.
						enable = false,
						-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
						url = '',
					},
				},
			},
		})
	end,
})

return M
