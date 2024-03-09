local M = {}

-- Setup KoalaVim with lazy.nvim
table.insert(M, {
	'KoalaVim/KoalaVim',
	priority = 9999999, -- Load KoalaVim first
	config = function()
		require('KoalaVim.conf').load()
		require('KoalaVim.conf').reg_autocmd()
		require('KoalaVim.state'):load()

		-- Override 's' default behavior
		local map = require('KoalaVim.utils.map').map
		map('n', 's', function() end, '', {})

		-- Load koala mode
		if vim.env.KOALA_MODE then
			vim.api.nvim_create_autocmd('VimEnter', {
				callback = function()
					vim.schedule(function()
						require('KoalaVim.utils.modes').load(vim.env.KOALA_MODE)
					end)
				end,
			})
		end
	end,
})

return M
