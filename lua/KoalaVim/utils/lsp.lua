local M = {}

local api = vim.api
local lsp = vim.lsp

local conf = require('KoalaVim').conf.lsp

function M.goto_next_diag(opts)
	local next = vim.diagnostic.get_next(opts)
	if next == nil then
		return
	end
	api.nvim_win_set_cursor(0, { next.lnum + 1, next.col })
	require('KoalaVim.utils.misc').center_screen()
end

function M.goto_prev_diag(opts)
	local prev = vim.diagnostic.get_prev(opts)
	if not prev then
		return
	end
	api.nvim_win_set_cursor(0, { prev.lnum + 1, prev.col })
	require('KoalaVim.utils.misc').center_screen()
end

function M.goto_next_error()
	M.goto_next_diag({ severity = vim.diagnostic.severity.ERROR })
end

function M.goto_prev_error()
	M.goto_prev_diag({ severity = vim.diagnostic.severity.ERROR })
end

function M.late_attach(on_attach_func)
	local clients = lsp.get_active_clients()
	for _, client in ipairs(clients) do
		local buffers = lsp.get_buffers_by_client_id(client.id)
		for _, buffer in ipairs(buffers) do
			on_attach_func(client, buffer)
		end
	end
end

-- Formatting is LazyVim's (`LazyVim.format`, conform + LSP fallback), KoalaVim applies its blacklists on top.
-- `lsp.format.*` blacklists apply to every format, `lsp.autoformat.*` only to the automatic format on save.

-- True while `LazyVim.format` runs without `force` (format on save, as opposed to `<leader>F`)
local autoformatting = false

local function in_list(list, value)
	return vim.tbl_contains(list or {}, value)
end

---@param name string conform formatter or LSP client name
function M.format_blacklisted(name)
	return in_list(conf.format.blacklist, name) or (autoformatting and in_list(conf.autoformat.blacklist, name))
end

---@param buf number
function M.ft_blacklisted(buf)
	local ft = vim.bo[buf].filetype
	return in_list(conf.format.blacklist_ft, ft) or (autoformatting and in_list(conf.autoformat.blacklist_ft, ft))
end

local servers_opts = nil

---@param name string LSP client name
function M.client_can_format(name)
	if M.format_blacklisted(name) then
		return false
	end

	-- `dont_format` is a KoalaVim flag on `opts.servers.<name>`
	servers_opts = servers_opts or LazyVim.opts('nvim-lspconfig').servers or {}
	local server = servers_opts[name]
	return not (type(server) == 'table' and server.dont_format)
end

-- Wrap a formatter before it's registered to `LazyVim.format`:
-- - filetype blacklists disable the formatter (also when forced)
-- - LSP clients are filtered by the blacklists and `dont_format`
local function guard_formatter(formatter)
	if formatter.koala_guarded then
		return formatter
	end
	formatter.koala_guarded = true

	local sources, format = formatter.sources, formatter.format
	local is_lsp = formatter.name == 'LSP'

	formatter.sources = function(buf)
		if M.ft_blacklisted(buf) then
			return {}
		end

		return vim.tbl_filter(function(name)
			if is_lsp then
				return M.client_can_format(name)
			end
			return not M.format_blacklisted(name)
		end, sources(buf))
	end

	formatter.format = function(buf)
		if M.ft_blacklisted(buf) then
			return
		end

		if is_lsp then
			-- Same as `LazyVim.lsp.formatter()` but with KoalaVim's client filter
			LazyVim.lsp.format({
				bufnr = buf,
				filter = function(client)
					return M.client_can_format(client.name)
				end,
			})
		else
			format(buf)
		end
	end

	return formatter
end

-- Apply KoalaVim's format policy (blacklists) to all of LazyVim's formatters, must run before they register.
function M.setup_format()
	if M._format_setup then
		return
	end
	M._format_setup = true

	for _, formatter in ipairs(LazyVim.format.formatters) do
		guard_formatter(formatter)
	end

	local register = LazyVim.format.register
	LazyVim.format.register = function(formatter)
		return register(guard_formatter(formatter))
	end

	-- Auto format (format on save) is the format without `force`
	local format = LazyVim.format.format
	LazyVim.format.format = function(opts)
		local prev = autoformatting
		autoformatting = not (opts and opts.force)
		local ok, err = pcall(format, opts)
		autoformatting = prev
		if not ok then
			error(err, 0)
		end
	end

	-- `blacklist_ft` disables auto format for the filetype, `format.blacklist_ft` also blocks the forced format (see above).
	local fts = vim.list_extend(vim.deepcopy(conf.format.blacklist_ft), conf.autoformat.blacklist_ft)
	if #fts > 0 then
		vim.api.nvim_create_autocmd('FileType', {
			desc = 'KoalaVim: disable auto format for blacklisted filetypes',
			group = vim.api.nvim_create_augroup('KoalaFormatBlacklist', { clear = true }),
			pattern = fts,
			callback = function(ev)
				vim.b[ev.buf].autoformat = false
			end,
		})
	end
end

-- Skip conform formatters that are on the blacklists (`opts.formatters` of conform)
function M.conform_blacklist(opts)
	local names = vim.list_extend(vim.deepcopy(conf.format.blacklist), conf.autoformat.blacklist)
	opts.formatters = opts.formatters or {}

	for _, name in ipairs(names) do
		local ok, builtin = pcall(require, 'conform.formatters.' .. name)
		local override = opts.formatters[name]
		-- Not a conform formatter (e.g. an LSP client), handled by `guard_formatter`
		if ok or override ~= nil then
			local function with_blacklist(config)
				config = vim.deepcopy(config or {})
				local prev = config.condition or (ok and builtin.condition) or nil
				config.condition = function(self, ctx)
					if M.format_blacklisted(name) then
						return false
					end
					return prev == nil or prev(self, ctx)
				end
				return config
			end

			if type(override) == 'function' then
				opts.formatters[name] = function(bufnr)
					return with_blacklist(override(bufnr))
				end
			else
				opts.formatters[name] = with_blacklist(override)
			end
		end
	end
end

-- The base config (signs, underline, ...) is `opts.diagnostics` of lspconfig (see plugins/lsp/diagnostics.lua),
-- the modes override only the virtual text/lines.
local DIAGNOSTICS_CFG = {
	{
		virtual_lines = false,
		virtual_text = false,
		diagflow = true,
	},
	{
		virtual_lines = true,
		virtual_text = false,
		diagflow = false,
	},
	{
		virtual_lines = false,
		virtual_text = {
			-- Show only errors
			severity = vim.diagnostic.severity.ERROR,
			prefix = require('KoalaVim.utils.icons').diagnostics.error,
		},
		signs = {
			priority = 8,
		},
		diagflow = false,
	},
}

local CURR_DIAG_CFG = DIAGNOSTICS_CFG[1]

function M.setup_diagnostic_signs()
	local icons = require('KoalaVim.utils.icons').diagnostics
	for severity, name in pairs(require('KoalaVim.utils.icons').severity_to_name) do
		local hlname = 'DiagnosticSign' .. name:gsub('^%l', string.upper)
		vim.fn.sign_define(hlname, { text = icons[name], texthl = hlname, numhl = '' })
	end
end

local _base_signs = nil

function M.set_diagnostics_mode(index)
	if _base_signs == nil then
		-- Signs of `opts.diagnostics`, modes may add to it (priority)
		local signs = vim.diagnostic.config().signs
		_base_signs = type(signs) == 'table' and signs or {}
	end

	CURR_DIAG_CFG = DIAGNOSTICS_CFG[index]
	vim.diagnostic.config({
		virtual_text = CURR_DIAG_CFG.virtual_text,
		virtual_lines = CURR_DIAG_CFG.virtual_lines,
		signs = vim.tbl_extend('force', _base_signs, CURR_DIAG_CFG.signs or {}),
	})
	if CURR_DIAG_CFG.diagflow then
		require('diagflow').enable()
	else
		require('diagflow').disable()
	end
end

-- Apply the initial diagnostics mode once LazyVim's lspconfig config applied `opts.diagnostics`
function M.init_diagnostics_mode()
	vim.api.nvim_create_autocmd('User', {
		pattern = 'LazyLoad',
		callback = function(ev)
			if ev.data == 'nvim-lspconfig' then
				M.set_diagnostics_mode(1)
				return true -- once
			end
		end,
	})
end

function M.enable_diagflow()
	if CURR_DIAG_CFG.diagflow then
		require('diagflow').enable()
	end
end

function M.disable_diagflow()
	if CURR_DIAG_CFG.diagflow then
		require('diagflow').disable()
	end
end

local CURR_DIAGNOSTICS_CFG = 1

function M.cycle_lsp_diagnostics()
	CURR_DIAGNOSTICS_CFG = CURR_DIAGNOSTICS_CFG + 1
	if CURR_DIAGNOSTICS_CFG > #DIAGNOSTICS_CFG then
		CURR_DIAGNOSTICS_CFG = 1
	end

	M.set_diagnostics_mode(CURR_DIAGNOSTICS_CFG)
end

return M
