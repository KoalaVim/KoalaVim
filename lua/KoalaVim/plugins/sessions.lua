local M = {}

KOALA_AUTOSAVE_SESSION = true
KOALA_SESSION_ENABLED = true

-- Disables session saving if a session already exists
function KoalaDisableAutoSession()
	local cwd_session = require('KoalaVim.utils.session').cwd_session()

	if require('possession.session').exists(cwd_session) then
		KOALA_AUTOSAVE_SESSION = false
		vim.notify('AutoSession Saving Disabled!')
	end
end

-- Disables session saving at all
function KoalaDisableSession()
	KOALA_AUTOSAVE_SESSION = false
end

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
				return require('KoalaVim.utils.session').cwd_session()
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
			vim.api.nvim_create_autocmd('VimEnter', {
				callback = function()
					vim.schedule(function()
						require('KoalaVim.utils.session').load_cwd_session()
					end)
				end,
			})
		end
	end,
})

return M
