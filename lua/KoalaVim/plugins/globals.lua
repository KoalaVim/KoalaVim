-- TODO: find a better solutions for globals.lua
local M = {}

HYDRAS = {}
HELPERS = {}
--TODO: some help files are ghost files
GHOST_FILETYPES = { 'fugitive', 'NvimTree' }

-- Compatibility shim (one release): the LSP/linter/formatter registries were removed.
-- Writes to them warn and, where possible, are forwarded to the plugin opts.
local function removed(name, replacement, forward)
	return setmetatable({}, {
		__newindex = function(_, key, value)
			local src = debug.getinfo(2, 'S').short_src
			require('KoalaVim.health').warn(
				string.format('[%s] was removed (set from %s), use %s instead', name, src, replacement)
			)
			if forward then
				forward(key, value)
			end
		end,
	})
end

local conform_formatters = {}
CONFORM_FORMATTERS = removed(
	'CONFORM_FORMATTERS',
	"`opts.formatters_by_ft` of 'stevearc/conform.nvim'",
	function(name, fts)
		conform_formatters[name] = fts
	end
)
LSP_SERVERS = removed('LSP_SERVERS', "`opts.servers` of 'neovim/nvim-lspconfig'")
NONE_LS_SRCS = removed('NONE_LS_SRCS', "`opts.linters_by_ft` of 'mfussenegger/nvim-lint'")

function LSP_SERVER(_)
	require('KoalaVim.health').warn(
		"[LSP_SERVER] was removed, use an `opts` function of 'neovim/nvim-lspconfig' that reads `require('KoalaVim').conf`"
	)
end

-- Forward `CONFORM_FORMATTERS[name] = { 'ft', mason = false|'package' }` to conform and mason
table.insert(M, {
	'stevearc/conform.nvim',
	opts = function(_, opts)
		opts.formatters_by_ft = opts.formatters_by_ft or {}
		for name, fts in pairs(conform_formatters) do
			for _, ft in ipairs(fts) do
				opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
				if not vim.tbl_contains(opts.formatters_by_ft[ft], name) then
					table.insert(opts.formatters_by_ft[ft], name)
				end
			end
		end
	end,
})

table.insert(M, {
	'mason-org/mason.nvim',
	opts = function(_, opts)
		opts.ensure_installed = opts.ensure_installed or {}
		for name, fts in pairs(conform_formatters) do
			local package = fts.mason == nil and name or fts.mason
			if package then
				table.insert(opts.ensure_installed, package)
			end
		end
	end,
})

return M
