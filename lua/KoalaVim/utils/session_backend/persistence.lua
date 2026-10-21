-- Session backend for the `lazyvim` flavor (folke/persistence.nvim)
-- Sessions are per cwd (and git branch). persistence has no user data in its sessions,
-- so the component state (build/debug/deploy) is stored in a sidecar json next to the session file.
local M = {}

local session = require('KoalaVim.utils.session')

---@return string
local function sidecar(file)
	return file .. '.json'
end

-- The session file persistence loads for the cwd (branch session first, then the plain one)
---@return string
local function cwd_file()
	local p = require('persistence')
	local file = p.current()
	if vim.fn.filereadable(file) == 0 then
		file = p.current({ branch = false })
	end
	return file
end

function M.exists_cwd()
	return vim.fn.filereadable(cwd_file()) == 1
end

function M.save()
	local p = require('persistence')
	-- `persistence.save` doesn't fire the events, only the autosave on exit does
	p.fire('SavePre')
	p.save()
	p.fire('SavePost')
end

function M.load_cwd()
	require('persistence').load()
end

function M.delete_cwd()
	local p = require('persistence')
	for _, file in ipairs({ p.current(), p.current({ branch = false }) }) do
		vim.fn.delete(file)
		vim.fn.delete(sidecar(file))
	end
end

function M.list()
	require('persistence').select()
end

-- `persistence.stop` disables the autosave on exit
function M.set_autosave(enabled)
	if not package.loaded['persistence'] then
		return
	end

	if enabled then
		require('persistence').start()
	else
		require('persistence').stop()
	end
end

-- Hooks the component state to persistence's events
function M.setup()
	local group = vim.api.nvim_create_augroup('koala_persistence_state', { clear = true })
	local pending = nil ---@type table?

	-- Collect before the save, write only if persistence did save (it skips when there are no file buffers)
	vim.api.nvim_create_autocmd('User', {
		group = group,
		pattern = 'PersistenceSavePre',
		callback = function()
			pending = session.collect_data()
		end,
	})
	vim.api.nvim_create_autocmd('User', {
		group = group,
		pattern = 'PersistenceSavePost',
		callback = function()
			if pending then
				local ok, json = pcall(vim.json.encode, pending)
				if ok then
					vim.fn.writefile({ json }, sidecar(require('persistence').current()))
				end
				pending = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd('User', {
		group = group,
		pattern = 'PersistenceLoadPost',
		callback = function()
			-- The session script sets `v:this_session` to the file it was sourced from
			local file = vim.v.this_session ~= '' and vim.v.this_session or cwd_file()
			local data = {}
			if vim.fn.filereadable(sidecar(file)) == 1 then
				local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(sidecar(file)), '\n'))
				if ok and type(decoded) == 'table' then
					data = decoded
				end
			end
			session.restore_data(data)
		end,
	})
end

return M
