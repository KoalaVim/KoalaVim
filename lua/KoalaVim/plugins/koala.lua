local M = {}

-- Setup KoalaVim with lazy.nvim
table.insert(M, {
	'KoalaVim/KoalaVim',
	priority = 9999999, -- Load KoalaVim first
	config = function(_, opts)
		require('KoalaVim').setup(opts)

		-- Override 's' default behavior
		local map = require('KoalaVim.utils.map').map
		map('n', 's', function() end, '', {})

		-- check for updates
		local update_checker = require('KoalaVim.utils.update_checker')
		update_checker.check()
	end,
})

return M
