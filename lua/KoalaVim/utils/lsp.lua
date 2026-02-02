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

local function _format(buf, win, async, blacklist, blacklist_ft)
	if vim.tbl_contains(blacklist_ft, vim.bo[buf].filetype) then
		return
	end

	local conform = require('conform')

	local formatters = conform.list_formatters(buf)

	if #formatters > 0 then
		formatters = vim.tbl_filter(function(formatter)
			return not vim.tbl_contains(blacklist, formatter.name)
		end, formatters)

		formatters = vim.tbl_map(function(formatter)
			return formatter.name
		end, formatters)
	end

	local cursor = api.nvim_win_get_cursor(win)

	require('conform').format({
		async = async,
		bufnr = buf,
		formatters = formatters,
		lsp_fallback = #formatters == 0, -- prioritize non-lsp formatters

		-- applied only for lsp
		filter = function(client)
			return not vim.tbl_contains(blacklist, client.name) and not LSP_SERVERS[client.name].dont_format
		end,
	}, function(_, did_edit) -- callback after formatting
		if not did_edit then
			return
		end

		-- write changes to formatted buffer and return to the current buffer
		local saved_view = vim.fn.winsaveview()
		vim.cmd('let buf=bufnr("%") | exec "' .. buf .. 'bufdo silent! write!" | exec "b" buf')

		-- restore view after bufdo recenters the view
		vim.fn.winrestview({ topline = saved_view.topline })

		-- restore cursor position after async formatting.
		-- workaround when cursor is on formatted line, it get mispositioned afterwards.
		api.nvim_win_set_cursor(win, cursor)
	end)
end

AUTO_FORMAT_BLACKLIST = nil
AUTO_FORMAT_FT_BLACKLIST = nil
function M.auto_format(async, buf, win)
	-- Lazy load and cache auto format blacklist
	AUTO_FORMAT_BLACKLIST = AUTO_FORMAT_BLACKLIST or vim.list_extend(conf.autoformat.blacklist, conf.format.blacklist)
	AUTO_FORMAT_FT_BLACKLIST = AUTO_FORMAT_FT_BLACKLIST
		or vim.list_extend(conf.autoformat.blacklist_ft, conf.format.blacklist_ft)
	_format(buf, win, async, AUTO_FORMAT_BLACKLIST, AUTO_FORMAT_FT_BLACKLIST)
end

function M.format(async)
	-- FIXME: support disabling all formatters from config
	_format(
		api.nvim_get_current_buf(),
		api.nvim_get_current_win(),
		async,
		conf.format.blacklist,
		conf.format.blacklist_ft
	)
end

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

local CURR_DIAG_CFG = DIAGNOSTICS_CFG[0]

function M.set_diagnostics_mode(index)
	CURR_DIAG_CFG = DIAGNOSTICS_CFG[index]
	CURR_DIAG_CFG.update_in_insert = false

	vim.diagnostic.config(CURR_DIAG_CFG)
	if CURR_DIAG_CFG.diagflow then
		require('diagflow').enable()
	else
		require('diagflow').disable()
	end
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
