local M = {}

-- TODO: config system
function M.setup(opts)
end

function M.init()
	local rdir = require('KoalaVim.utils.require_dir')

	rdir.require('config', 'KoalaVim')
	rdir.require('config/keymaps', 'KoalaVim')


	-- Lazy load config files
	vim.api.nvim_create_autocmd('User', {
		pattern = 'LazyVimStarted',
		callback = function()
			rdir.recursive_require('config/lazy', 'KoalaVim')

			-- Let user config to lazy load his config
			vim.api.nvim_exec_autocmds('User', {
				pattern = 'KoalaVimStarted',
				modeline = false,
			})

			-- TODO: remove vim script from my KoalaVim
			-- 			vim.cmd([[
			-- source $HOME/.config/nvim/vim/file_util.vim
			-- ]])
		end,
	})
end

return M
