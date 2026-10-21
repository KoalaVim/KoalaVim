local M = {}

-- Session globals, implemented in the session adapter (the backend follows the flavor)

-- Disables auto session saving if a session already exists
function KoalaDisableAutoSession(silent)
	require('KoalaVim.utils.session').disable_if_exists(silent)
end

-- Disables auto session saving at all
function KoalaDisableSession()
	require('KoalaVim.utils.session').disable()
end

-- Enables auto session saving
function KoalaEnableSession()
	require('KoalaVim.utils.session').enable()
end

-- Delete current session and disable auto saving
function KoalaDeleteCurrentSession()
	require('KoalaVim.utils.session').delete_cwd()
end

-- Session manager — save/restore workspace per cwd with auto-save hooks
-- (koala flavor, the lazyvim flavor uses persistence.nvim)
table.insert(M, {
	'jedrzejboczar/possession.nvim',
	enabled = function()
		return require('KoalaVim.flavor').is('koala')
	end,
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
				return require('KoalaVim.utils.session').collect_data()
			end,
			after_load = function(_, user_data)
				require('KoalaVim.utils.session').restore_data(user_data)
			end,
		},
		plugins = {
			delete_hidden_buffers = {
				hooks = {
					'before_load',
				},
			},
			-- fugitive = true,
		},
	},
	config = function(_, opts)
		require('possession').setup(opts)
		require('KoalaVim.utils.session').startup()
	end,
})

-- Session manager of LazyVim (lazyvim flavor), extends LazyVim's spec
-- Loaded on startup (instead of `BufReadPre`) to apply the disable controls and auto load on restart
table.insert(M, {
	'folke/persistence.nvim',
	enabled = function()
		return require('KoalaVim.flavor').is('lazyvim')
	end,
	lazy = false,
	config = function(_, opts)
		require('persistence').setup(opts)
		require('KoalaVim.utils.session_backend.persistence').setup()

		-- persistence starts the autosave in `setup`
		if not KOALA_AUTOSAVE_SESSION then
			require('persistence').stop()
		end
		require('KoalaVim.utils.session').startup()
	end,
})

return M
