local M = {}

local usercmd = require('KoalaVim.utils.cmd')

-- TODO: restore fugitive
-- TODO: handle zombie files

KOALA_AUTOSAVE_SESSION = true
KOALA_SESSION_LOADED = false

-- Disables auto session saving if a session already exists
function KoalaDisableAutoSession(silent)
	local cwd_session = require('KoalaVim.utils.session').cwd_session()

	if require('possession.session').exists(cwd_session) then
		KOALA_AUTOSAVE_SESSION = false
		if not silent then
			vim.notify('AutoSession Saving Disabled! (:SaveSession to override)')
		end
	end
end

-- Disables auto session saving at all
function KoalaDisableSession()
	KOALA_AUTOSAVE_SESSION = false
end

-- Enables auto session saving
function KoalaEnableSession()
	if KOALA_AUTOSAVE_SESSION == false then
		KOALA_AUTOSAVE_SESSION = true
		vim.notify('AutoSession Saving Enabled!')
	end
end

-- Delete current session and disable auto saving
function KoalaDeleteCurrentSession()
	local cwd_session = require('KoalaVim.utils.session').cwd_session()

	require('possession.session').delete(cwd_session, {})
	vim.notify('Session Deleted! AutoSession Saving Disabled!')
	KOALA_AUTOSAVE_SESSION = false
end

table.insert(M, {
	'jedrzejboczar/possession.nvim',
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
			save = 'SaveNamedSession',
			load = 'LoadNamedSession',
			rename = 'RenameSession',
			close = nil,
			delete = 'DeleteNamedSession',
			show = nil,
			list = nil,
			migrate = nil,
		},
		hooks = {
			before_save = function(_)
				local data = {}
				data.build = require('KoalaVim.utils.build').get_session_data()
				data.debug = require('KoalaVim.utils.debug').get_session_data()

				return data
			end,
			after_load = function(_, user_data)
				require('KoalaVim.utils.build').restore_session_data(user_data.build or {})
				require('KoalaVim.utils.debug').restore_session_data(user_data.debug or {})
				KOALA_SESSION_LOADED = true
			end,
		},
		plugins = {
			delete_hidden_buffers = {
				hooks = {
					'before_load',
				},
			},
			fugitive = true,
		},
	},
	config = function(_, opts)
		local auto_load_session = false
		if not vim.env.KOALA_NO_SESSION then
			auto_load_session = vim.env.KOALA_RESTART

			-- Disable session saving if files passed in argline
			-- Load session only if dirs passed at the cmdline
			local argv = vim.fn.argv()
			for i, arg in ipairs(argv) do
				if vim.fn.isdirectory(arg) ~= 1 then
					KoalaDisableSession()
					auto_load_session = false
					break
				else
					-- FIXME: sometimes this crashes nvim
					auto_load_session = true
					vim.api.nvim_set_current_dir(arg)
				end
			end
		else
			KoalaDisableSession()
		end

		require('possession').setup(opts)

		usercmd.create('SessionList', 'Sessions: open sessions list', function()
			require('KoalaVim.utils.session').list_sessions()
		end, {})

		usercmd.create('SaveSession', 'Sessions: save current session as the cwd session', function()
			KoalaEnableSession()
			local cwd_session = require('KoalaVim.utils.session').cwd_session()
			require('possession.session').save(cwd_session, { no_confirm = true })
		end, {})

		usercmd.create('LoadSession', 'Sessions: Load the cwd session', function()
			require('KoalaVim.utils.session').load_cwd_session()
		end, {})

		usercmd.create('DeleteSession', 'Sessions: Delete the current session', function()
			KoalaDeleteCurrentSession()
		end, {})

		if auto_load_session then
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
