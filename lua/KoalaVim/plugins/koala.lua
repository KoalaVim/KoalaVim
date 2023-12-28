local M = {}

-- Setup KoalaVim with lazy.nvim
table.insert(M, {
	'KoalaVim/KoalaVim',
	priority = 9999999, -- Load KoalaVim first
	config = function()
		require('KoalaVim.conf').load()
		require('KoalaVim.conf').reg_autocmd()

		-- Override 's' default behavior
		local map = require('KoalaVim.utils.map').map
		map('n', 's', function() end, '', {})
	end,
})

return M
