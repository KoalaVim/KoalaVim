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
	-- local ft = vim.bo[buf].filetype
	-- local available_nls = require('null-ls.sources').get_available(ft, 'NULL_LS_FORMATTING')

	require('conform').format({ async = async, bufnr = buf })

	-- vim.lsp.buf.format({
	-- 	async = async,
	-- 	bufnr = buf,
	-- 	filter = function(client)
	-- 		if #available_nls > 0 then
	-- 			for _, nls_src in ipairs(available_nls) do
	-- 				if vim.tbl_contains(blacklist, nls_src.name) then
	-- 					return false
	-- 				end
	-- 			end
	-- 			return client.name == 'null-ls'
	-- 		end
	--
	-- 		if vim.tbl_contains(blacklist, client.name) then
	-- 			return false
	-- 		end
	--
	-- 		return client.name ~= 'null-ls'
	-- 	end,
	-- })
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
