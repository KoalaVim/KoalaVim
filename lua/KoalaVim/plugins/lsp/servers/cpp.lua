local M = {}

local clangd_cmd = {
	'clangd',
	'--background-index',
	'--fallback-style=none',
	'--header-insertion=never',
	'--all-scopes-completion',
	'--cross-file-rename',
}

if vim.fn.has('wsl') == 1 then
	table.insert(clangd_cmd, '-j=4') -- Limit resources on wsl
end

-- clangd and cmake (neocmake, replaces cmake-language-server) come from LazyVim's clangd/cmake extras
table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = {
		servers = {
			cmake = { enabled = false }, -- Don't auto-enable a leftover cmake-language-server install
			clangd = {
				cmd = clangd_cmd,
				filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
			},
		},
	},
})

-- Tool to build CMake projects, regenerates the project on save. Wasn't part of KoalaVim
table.insert(M, {
	'Civitasv/cmake-tools.nvim',
	enabled = false,
})

local add_r_new_line = 'i\\r\\n<Esc>'
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'c', 'cpp' },
	callback = function(events)
		local map_buffer = require('KoalaVim.utils.map').map_buffer
		map_buffer(events.buf, 'n', '<leader>n', add_r_new_line, 'Add newline')
	end,
})

return M
