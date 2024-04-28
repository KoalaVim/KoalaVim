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

local function _format(buf, async, blacklist)
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

	local win = api.nvim_get_current_win()
	local cursor = api.nvim_win_get_cursor(win)

	require('conform').format({
		async = async,
		bufnr = buf,
		formatters = formatters,
		lsp_fallback = #formatters == 0, -- prioritize non-lsp formatters

		-- applied only for lsp
		filter = function(client)
			return not vim.tbl_contains(blacklist, client.name)
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
function M.auto_format(async, buf)
	-- Lazy load and cache auto format blacklist
	AUTO_FORMAT_BLACKLIST = AUTO_FORMAT_BLACKLIST or vim.list_extend(conf.autoformat.blacklist, conf.format.blacklist)
	_format(buf, async, AUTO_FORMAT_BLACKLIST)
end

function M.format(async)
	_format(vim.api.nvim_get_current_buf(), async, conf.format.blacklist)
end

return M
