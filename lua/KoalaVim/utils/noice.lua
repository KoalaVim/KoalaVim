local M = {}

function M.show_signature()
	local noice_sig = require('noice.lsp.signature')
	local buf = vim.api.nvim_get_current_buf()
	local current_char = noice_sig.get_char(buf)

	local params = vim.lsp.util.make_position_params(0, 'utf-16')
	vim.lsp.buf_request(buf, 'textDocument/signatureHelp', params, function(err, result, ctx)
		noice_sig.on_signature(err, result, ctx, {
			trigger = true,
			stay = function()
				return current_char == noice_sig.get_char(buf)
			end,
		})
	end)
end

return M
