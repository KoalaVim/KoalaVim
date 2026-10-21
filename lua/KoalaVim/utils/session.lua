-- Session adapter, the backend follows the flavor:
-- koala: possession.nvim (also supports named sessions), lazyvim: persistence.nvim
local M = {}

local usercmd = require('KoalaVim.utils.cmd')

KOALA_AUTOSAVE_SESSION = true
KOALA_SESSION_LOADED = false

---@return { exists_cwd: fun(): boolean, save: fun(), load_cwd: fun(), delete_cwd: fun(), list: fun(), set_autosave: fun(enabled: boolean) }
local function backend()
	local name = require('KoalaVim.flavor').pick({ koala = 'possession', lazyvim = 'persistence' })
	return require('KoalaVim.utils.session_backend.' .. name)
end

function M.cwd_session()
	return require('KoalaVim.utils.path').escaped_session_name_from_cwd()
end

-- Component state, saved with the session and restored after it's loaded
local pre_save_hooks = {} ---@type table<string, fun(): table?>
local post_load_hooks = {} ---@type table<string, fun(data: table)>

--- Register a hook that runs before the session is saved, its returned data is saved with the session
---@param name string
---@param fn fun(): table?
function M.on_pre_save(name, fn)
	pre_save_hooks[name] = fn
end

--- Register a hook that runs after the session is loaded, it receives the data `on_pre_save` returned
---@param name string
---@param fn fun(data: table)
function M.on_post_load(name, fn)
	post_load_hooks[name] = fn
end

-- For the backends, runs the pre save hooks
---@return table
function M.collect_data()
	local data = {}
	for name, fn in pairs(pre_save_hooks) do
		data[name] = fn()
	end
	return data
end

-- For the backends, runs the post load hooks
---@param data table
function M.restore_data(data)
	for name, fn in pairs(post_load_hooks) do
		fn(data and data[name] or {})
	end
	KOALA_SESSION_LOADED = true
end

M.on_pre_save('build', function()
	return require('KoalaVim.utils.build').get_session_data()
end)
M.on_post_load('build', function(data)
	require('KoalaVim.utils.build').restore_session_data(data)
end)
M.on_pre_save('debug', function()
	return require('KoalaVim.utils.debug').get_session_data()
end)
M.on_post_load('debug', function(data)
	require('KoalaVim.utils.debug').restore_session_data(data)
end)

function M.exists_cwd()
	return backend().exists_cwd()
end

-- Save the current state as the cwd session and enable the autosave
function M.save()
	M.enable()
	backend().save()
end

function M.load_cwd()
	if not backend().exists_cwd() then
		vim.notify("Session doesn't exist!")
		return
	end
	backend().load_cwd()
	M.enable()
end
M.load_cwd_session = M.load_cwd

-- Delete the cwd session and disable the autosave
function M.delete_cwd()
	backend().delete_cwd()
	vim.notify('Session Deleted! AutoSession Saving Disabled!')
	M.disable()
end

function M.list()
	backend().list()
end
M.list_sessions = M.list

-- Disables the autosave
function M.disable()
	KOALA_AUTOSAVE_SESSION = false
	backend().set_autosave(false)
end

-- Disables the autosave if the cwd has a session
function M.disable_if_exists(silent)
	if M.exists_cwd() then
		M.disable()
		if not silent then
			vim.notify('AutoSession Saving Disabled! (:SaveSession to override)')
		end
	end
end

-- Enables the autosave
function M.enable()
	if KOALA_AUTOSAVE_SESSION == false then
		KOALA_AUTOSAVE_SESSION = true
		backend().set_autosave(true)
		vim.notify('AutoSession Saving Enabled!')
	end
end

-- Called from the backend plugin's config, applies the startup disable controls, creates the commands
-- and loads the cwd session on restart
function M.startup()
	local auto_load_session = false
	if not vim.env.KOALA_NO_SESSION then
		auto_load_session = vim.env.KOALA_RESTART

		-- Disable session saving if files passed in argline
		-- Load session only if dirs passed at the cmdline
		local argv = vim.fn.argv()
		for _, arg in ipairs(argv) do
			if vim.fn.isdirectory(arg) ~= 1 then
				M.disable()
				auto_load_session = false
				break
			else
				auto_load_session = true
				vim.api.nvim_set_current_dir(arg)
			end
		end
	else
		M.disable()
	end

	usercmd.create('SessionList', 'Sessions: open sessions list', M.list, {})
	usercmd.create('SaveSession', 'Sessions: save current session as the cwd session', M.save, {})
	usercmd.create('LoadSession', 'Sessions: Load the cwd session', M.load_cwd, {})
	usercmd.create('DeleteSession', 'Sessions: Delete the current session', M.delete_cwd, {})

	if auto_load_session then
		vim.api.nvim_create_autocmd('VimEnter', {
			callback = function()
				vim.schedule(M.load_cwd)
			end,
		})
	end
end

return M
