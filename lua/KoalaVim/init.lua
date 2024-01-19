local M = {}

M._debug_file = nil

-- Global debug function.
-- Using notify, use `:Noice` or `<leader>N` to see the output
-- Goes to: `/tmp/kvim.log` as well
--
-- obj can be a table or a vlue
-- label: optional string to label debug messages
DEBUG = function(obj, label)
	local title = ''
	local is_table = type(obj) == 'table'

	if is_table then
		title = (label or '') .. ' (table)'
	else
		title = (label and label .. '=' or '') .. tostring(obj)
	end

	local info = debug.getinfo(2)
	title = info.short_src .. ':' .. info.currentline .. ': ' .. title
	-- Using notify because we have noice :)
	vim.notify(title, vim.log.levels.DEBUG)
	local text = title
	if is_table then
		text = text .. vim.inspect(obj)
		vim.notify(vim.inspect(obj), vim.log.levels.DEBUG)
	end

	M._debug_file:write(text .. '\n')
end

local function init_debug()
	-- TODO: log cycle
	M._debug_file = io.open('/tmp/kvim.log', 'w')
end

function M.init()
	if vim.env.KOALA_DEBUG then
		init_debug()
	else
		-- Disable debug
		DEBUG = function() end
	end

	vim.api.nvim_create_user_command('LazyRestoreLogged', function(opts)
		local ret = require('KoalaVim.utils.restore').restore_logged({ plugins = opts.fargs })
		print(vim.json.encode(ret))
	end, { nargs = '*' })

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

M.conf = {}
M.state = {}

return M
