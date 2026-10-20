---@diagnostic disable: assign-type-mismatch
local opt = vim.opt

-- This file runs after LazyVim's options (`LazyVimOptionsDefaults`).
-- Reset the LazyVim options that KoalaVim doesn't set to Neovim's defaults, KoalaVim's own values follow.
-- stylua: ignore
for _, name in ipairs({
	'autowrite', 'clipboard', 'completeopt', 'conceallevel', 'confirm', 'fillchars', 'foldmethod', 'foldtext',
	'formatexpr', 'formatoptions', 'grepformat', 'grepprg', 'jumpoptions', 'laststatus', 'linebreak', 'list',
	'pumblend', 'pumheight', 'ruler', 'sessionoptions', 'shiftround', 'shortmess', 'showmode', 'sidescrolloff',
	'smartcase', 'smartindent', 'splitkeep', 'statuscolumn', 'undolevels', 'virtualedit', 'wildmode', 'winminwidth',
}) do
	vim.cmd('set ' .. name .. '&')
end
vim.g.markdown_recommended_style = nil
vim.g.trouble_lualine = false -- KoalaVim's statusline doesn't show trouble symbols
vim.g.lazyvim_cmp = 'nvim-cmp' -- LazyVim's default (blink.cmp) disables nvim-cmp
do
	-- LazyVim's typescript extra picks the server from this (reset by LazyVim's options)
	local tsgo = require('KoalaVim').conf.lsp.tsgo
	vim.g.lazyvim_ts_lsp = tsgo.enabled == true and 'tsc' or 'vtsls'
end

opt.number = true
opt.relativenumber = true
opt.autoindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smarttab = true
opt.softtabstop = 4
opt.cursorline = true
opt.ignorecase = true
opt.splitright = true
opt.splitbelow = true
opt.swapfile = false
opt.wrap = true
opt.undofile = true -- enable persistent undo
opt.scrolloff = 4 -- minimal number of screen lines to keep above and below the cursor.
opt.smoothscroll = true
opt.updatetime = 100 -- mainly for trld.nvim which utilize CursorHold autocmd
opt.formatoptions:append('cro/j') -- continue comments when going down a line
opt.sessionoptions:remove('options') -- don't save keymaps and local options
opt.foldlevelstart = 99 -- no auto folding
opt.mouse = 'a' -- Enable mouse when guest are using my nvim
opt.signcolumn = 'yes:1' -- Enable 1 signs in the column
opt.cmdheight = 0
opt.report = 2147483647 -- Don't report yanked/deleted lines
opt.diffopt:append('linematch:60')
opt.timeoutlen = 300

-- TODO: move to personal
vim.g.c_syntax_for_h = 1 -- `.h` files are `c` instead of `cpp`
