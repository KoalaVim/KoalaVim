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

-- TODO fix me
local function _format(async, blacklist)
	local buf = vim.api.nvim_get_current_buf()
	local conform = require('conform')

	local formatters = conform.list_formatters(buf)
	if #formatters > 0 then
		for _, formatter in ipairs(formatters) do
			if vim.tbl_contains(blacklist, formatter.name) then
				return -- blacklisted
			end
		end
	end

	require('conform').format({
		async = async,
		bufnr = buf,
		lsp_fallback = true,

		-- applied only for lsp
		filter = function(client)
			return not vim.tbl_contains(blacklist, client.name)
		end,
	})
end

AUTO_FORMAT_BLACKLIST = nil
function M.auto_format(async)
	-- Lazy load and cache auto format blacklist
	AUTO_FORMAT_BLACKLIST = AUTO_FORMAT_BLACKLIST or vim.list_extend(conf.autoformat.blacklist, conf.format.blacklist)
	_format(async, AUTO_FORMAT_BLACKLIST)
end

function M.format(async)
	_format(async, conf.format.blacklist)
end

return M
