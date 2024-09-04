local M = {}

table.insert(M, {
	'aklt/plantuml-syntax',
})

table.insert(M, {
	'ofirgall/plantuml.nvim', -- fork
	ft = {
		'iuml',
		'plantuml',
		'pu',
		'puml',
		'wsd',
	},
	opts = {
		image_renderer = { -- for KoalaVim
			type = 'image',
			options = {
				prog = 'feh',
				dark_mode = false,
			},
		},
	},
	config = function(_, opts)
		require('plantuml').setup(opts)

		local image_renderer = require('plantuml').create_renderer(opts.image_renderer)
		require('KoalaVim.utils.cmd').create('UML', 'Render plantuml as image', function()
			require('plantuml').render_file(image_renderer, vim.api.nvim_buf_get_name(0))
		end)
	end,
})

return M
