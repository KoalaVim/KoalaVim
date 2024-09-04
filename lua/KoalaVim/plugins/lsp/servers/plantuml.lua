local M = {}

table.insert(M, {
	'https://gitlab.com/itaranto/plantuml.nvim',
	opts = {},
	config = function(_, opts)
		require('plantuml').setup(opts)
	end,
})

return M
