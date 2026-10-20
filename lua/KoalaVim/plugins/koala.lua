local M = {}

-- KoalaVim meta-plugin itself: koala modes (config, state and autocmds are loaded in `KoalaVim.init()`)
table.insert(M, {
	'KoalaVim/KoalaVim',
	priority = 9999999, -- Load KoalaVim first
	config = function()
		-- Override 's' default behavior
		local map = require('KoalaVim.utils.map').map
		map('n', 's', function() end, '', {})

		-- Load koala mode
		if vim.env.KOALA_MODE then
			vim.api.nvim_create_autocmd('VimEnter', {
				callback = function()
					vim.schedule(function()
						require('KoalaVim.utils.modes').load(vim.env.KOALA_MODE, vim.env.KOALA_ARGS)
					end)
				end,
			})
		end
	end,
})

return M
