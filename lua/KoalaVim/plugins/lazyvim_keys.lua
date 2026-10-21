local M = {}

-- Applies the contested-keys table to the `keys` of LazyVim's plugin specs (core and the extras KoalaVim imports) and
-- sets the which-key groups per flavor, see `KoalaVim.keymaps.remap` / `KoalaVim.keymaps.contested`.
--
-- `remap.keys` only sees the fragments merged before it, KoalaVim's own keys must be built with `kkeys` (they are
-- recognized and left alone). LSP server keys are in `plugins/lsp/keys.lua`.
--
-- Plugins with LazyVim keys (found by dumping `Plugin.values(plugin, 'keys', true)` of every plugin and tracking the
-- module each `keys` fragment is imported from, `lazyvim.plugins.*`):
--   core:   snacks.nvim (util/ui), trouble.nvim, todo-comments.nvim, which-key.nvim (editor), noice.nvim,
--           bufferline.nvim (ui), conform.nvim (formatting), mason.nvim (lsp), persistence.nvim (util)
--   extras: snacks.nvim (picker/explorer), todo-comments.nvim (snacks_picker), nvim-dap + nvim-dap-ui (dap.core),
--           vim-illuminate (editor.illuminate), nvim-dap-python + venv-selector.nvim (lang.python),
--           markdown-preview.nvim (lang.markdown)
-- Add a plugin here when an extra or a LazyVim bump brings keys to a new one (`check()` flags the collisions).
--
-- `optional = true`: the fragment never adds a plugin on its own, so it's harmless for plugins that are disabled in a
-- flavor (persistence in the koala flavor) or that no import brings.
local plugins = {
	'folke/snacks.nvim',
	'folke/trouble.nvim',
	'folke/todo-comments.nvim',
	'folke/which-key.nvim',
	'folke/noice.nvim',
	'folke/persistence.nvim',
	'akinsho/bufferline.nvim',
	'stevearc/conform.nvim',
	'mason-org/mason.nvim',
	'mfussenegger/nvim-dap',
	'rcarriga/nvim-dap-ui',
	'mfussenegger/nvim-dap-python',
	'linux-cultist/venv-selector.nvim',
	'iamcco/markdown-preview.nvim',
	'RRethy/vim-illuminate',
}

for _, repo in ipairs(plugins) do
	table.insert(M, {
		repo,
		optional = true,
		keys = function(plugin, keys)
			return require('KoalaVim.keymaps.remap').keys(plugin, keys)
		end,
	})
end

--------------------------------------------------------------------------------------------------------------------
-- which-key groups
--------------------------------------------------------------------------------------------------------------------

-- LazyVim's groups that KoalaVim's layout replaces (koala flavor), the keys under them moved or were dropped
local koala_drop = {
	'<leader><tab>',
	'<leader>c',
	'<leader>d',
	'<leader>dp',
	'<leader>s',
	'<leader>b',
	'<leader>w',
	'<leader>q',
	'<leader>gh',
	'gs',
}

-- Groups KoalaVim adds, `{ lhs, group }`
local koala_groups = {
	{ '<leader>v', 'code' },
	{ '<leader>r', 'run/debug' },
	{ '<leader>q', 'quit/buffers' },
	{ '<leader>z', 'lazy' },
	{ '<leader>a', 'ai' },
	{ '<leader>h', 'hunks' },
	{ '<leader>uP', 'profiler' },
	{ '<leader>fc', 'current word/dir' },
	{ '<leader>fcd', 'current dir' },
	{ '<leader>fN', 'noice' },
}

local lazyvim_groups = {
	{ '<leader>a', 'ai' },
	{ '<leader>gO', 'octo' },
	{ '<leader>r', 'run/build' },
	{ '<leader>h', 'hunks' },
	{ '<leader>fC', 'current word/dir' },
	{ '<leader>fCd', 'current dir' },
	{ '<leader>fN', 'spectre' },
}

--- LazyVim's `opts.spec` is a list holding group tables (`{ mode = {...}, { lhs, group = ... }, ... }`) and single
--- entries. Returns a copy without the entries whose lhs is in `drop`.
---@param spec table
---@param drop table<string, true>  canonical lhs
---@return table
local function filter_spec(spec, drop)
	local canon = require('KoalaVim.keymaps.remap').canon
	local ret = {}
	for k, v in pairs(spec) do
		if type(k) ~= 'number' then
			ret[k] = v
		end
	end
	for _, entry in ipairs(spec) do
		if type(entry) ~= 'table' then
			ret[#ret + 1] = entry
		elseif type(entry[1]) == 'string' then
			if not drop[canon(entry[1])] then
				ret[#ret + 1] = entry
			end
		else
			ret[#ret + 1] = filter_spec(entry, drop)
		end
	end
	return ret
end

table.insert(M, {
	'folke/which-key.nvim',
	optional = true,
	-- LazyVim extends `opts.spec` (`opts_extend`), this fragment runs after the groups of LazyVim and its extras
	opts = function(_, opts)
		local flavor = require('KoalaVim.flavor')
		local canon = require('KoalaVim.keymaps.remap').canon

		local groups = lazyvim_groups
		if flavor.get() == 'koala' then
			local drop = {}
			for _, lhs in ipairs(koala_drop) do
				drop[canon(lhs)] = true
			end
			opts.spec = filter_spec(opts.spec or {}, drop)
			groups = koala_groups
		end

		local spec = { mode = { 'n', 'x' } }
		for _, group in ipairs(groups) do
			spec[#spec + 1] = { group[1], group = group[2] }
		end
		opts.spec = opts.spec or {}
		table.insert(opts.spec, spec)
	end,
})

return M
