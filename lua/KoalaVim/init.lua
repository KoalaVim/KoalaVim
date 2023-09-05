local M = {}

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
