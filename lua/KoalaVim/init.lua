local M = {}

DEBUG_MODE = true -- TODO: opts

-- Global debug function
-- obj can be a table or a vlue
-- label: optional string to label debug messages
function DEBUG(obj, label)
	if not DEBUG_MODE then
		return
	end

	local title = ''
	local is_table = type(obj) == 'table'

	if is_table then
		title = (label or '') .. ' (table)'
	else
		title = label .. '=' .. obj
	end

	local info = debug.getinfo(2)
	title = info.short_src .. ':' .. info.currentline .. ': ' .. title
	-- Using notify because we have noice :)
	vim.notify(title, vim.log.levels.DEBUG)
	if is_table then
		vim.notify(vim.inspect(obj), vim.log.levels.DEBUG)
	end
end

function M.setup(opts)
	require('KoalaVim.opts').load_opts(opts)
end

function M.init()
	local rdir = require('KoalaVim.utils.require_dir')

	rdir.recursive_require('config', 'KoalaVim')

	-- Lazy load config files
	vim.api.nvim_create_autocmd('User', {
		pattern = 'LazyVimStarted',
		callback = function()
			rdir.recursive_require('config_lazy', 'KoalaVim')

			-- Let user config to lazy load his config
			vim.api.nvim_exec_autocmds('User', {
				pattern = 'KoalaVimStarted',
				modeline = false,
			})
		end,
	})
end

M.opts = require('KoalaVim.opts').default_opts

return M
