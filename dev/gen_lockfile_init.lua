-- This file generate clean lazy-lockfile
-- It must produce consistent output regardless of the developer's personal config.
-- Personal config can affect the lazy/ directory (disabling plugins removes them from disk),
-- so we preserve existing lockfile entries for spec plugins that are not installed.

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
lazy_cfg.plugins['KoalaVim']._.is_local = true

-- Snapshot existing lockfile entries before lock.update() clears them.
-- Plugins that are not installed (e.g. disabled by personal config) would be
-- dropped by lock.update(); we restore them from this snapshot afterward.
local Lock = require('lazy.manage.lock')
Lock.load()
local prev_lock = vim.deepcopy(Lock.lock)

-- Write lockfile (records only installed plugins)
Lock._loaded = false
Lock.update()

-- Restore entries for spec plugins that are missing from disk
Lock._loaded = false
Lock.load()
local patched = false
for _, plugin in pairs(lazy_cfg.plugins) do
	if not plugin._.is_local and not plugin._.installed then
		local old_entry = prev_lock[plugin.name]
		if old_entry then
			Lock.lock[plugin.name] = old_entry
			patched = true
		else
			io.stderr:write('WARNING: ' .. plugin.name .. ' is not installed and has no previous lockfile entry\n')
		end
	end
end

-- Re-write lockfile if we restored any entries
if patched then
	local names = vim.tbl_keys(Lock.lock)
	table.sort(names)

	vim.fn.mkdir(vim.fn.fnamemodify(lazy_cfg.options.lockfile, ':p:h'), 'p')
	local f = assert(io.open(lazy_cfg.options.lockfile, 'wb'))
	f:write('{\n')
	for n, name in ipairs(names) do
		local info = Lock.lock[name]
		f:write(([[  %q: { "branch": %q, "commit": %q }]]):format(name, info.branch, info.commit))
		if n ~= #names then
			f:write(',\n')
		end
	end
	f:write('\n}\n')
	f:close()
end

print('1')
