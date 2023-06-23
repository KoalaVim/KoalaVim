local M = {}

KOALA_AUTOSAVE_SESSION = true

table.insert(M, {
	'ofirgall/possession.nvim', -- fork
	dependencies = {
		'nvim-lua/plenary.nvim',
	},
	opts = {
		silent = true,
		-- Auto-session with possession.nvim
		autosave = {
			current = true,
			tmp = function()
				return KOALA_AUTOSAVE_SESSION
			end,
			tmp_name = function()
				return require('KoalaVim.utils.path').escaped_session_name_from_cwd()
			end,
		},
		commands = {
			save = 'SessionSave',
			load = 'SessionLoad',
			rename = 'SessionRename',
			close = 'SessionClose',
			delete = 'SessionDelete',
			show = 'SessionShow',
			list = nil,
			migrate = nil,
		},
	},
	config = function(_, opts)
		require('possession').setup(opts)
		require('telescope').load_extension('possession')

		vim.api.nvim_create_user_command('SessionList', function()
			require('KoalaVim.utils.session').list_sessions()
		end, {})

		if vim.env.KOALA_RESTART then
			api.nvim_create_autocmd('VimEnter', {
				callback = function()
					vim.schedule(function()
						vim.cmd(':SessionLoad ' .. require('KoalaVim.utils.path').escaped_session_name_from_cwd())
					end)
				end,
			})
		end
	end,
})

return M
