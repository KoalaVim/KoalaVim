-- This file generate clean lazy-lockfile

if vim.env['KOALA_LOCKFILE_DST'] == nil then
	print('missing env var: `KOALA_LOCKFILE_DST`')
	os.exit(1)
end

local lazy_path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim/'
vim.opt.rtp:prepend(lazy_path)
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/KoalaVim/')

local lazy_opts = {
	defaults = {
		lazy = false,
		verison = false,
	},
	checker = {
		-- automatically check for plugin updates
		enabled = false,
	},
	change_detection = {
		-- Don't auto reload config
		enabled = false,
	},
}

lazy_opts.spec = require('KoalaVim.spec')
lazy_opts.lockfile = vim.env['KOALA_LOCKFILE_DST']

-- Load lazy options
local lazy_cfg = require('lazy.core.config')
lazy_cfg.options = vim.tbl_deep_extend('force', lazy_cfg.defaults, lazy_opts)
lazy_cfg.me = lazy_path -- Set .me for lazy

-- Load plugins from spec
require('lazy.core.plugin').load()

-- Remove KoalaVim from lockfile
for key, _ in pairs(lazy_cfg.plugins) do
	if key == 'KoalaVim' then
		lazy_cfg.plugins['KoalaVim']._.is_local = true
		break
	end
end

-- Write lockfile
require('lazy.manage.lock').update()

print('1')
