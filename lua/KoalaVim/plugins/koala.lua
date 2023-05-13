local M = {}

-- Setup KoalaVim with lazy.nvim
table.insert(M, {
	'ofirgall/KoalaVim',
	priority = 9999999, -- Load KoalaVim first
	config = function(_, opts)
		require('KoalaVim').setup(opts)
	end,
})

return M

