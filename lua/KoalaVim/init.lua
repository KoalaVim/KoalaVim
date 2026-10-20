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
	M._debug_file = io.open(vim.env.KOALA_DEBUG_OUT, 'w')
end

-- Config modules LazyVim loads by itself from the user's config (`config.<name>`)
local LAZYVIM_USER_MODULES = { 'options', 'keymaps', 'autocmds' }

-- Load the user's `config/**` files that LazyVim doesn't load by itself.
-- LazyVim requires `config.{options,keymaps,autocmds}` only if they resolve to a module,
-- e.g. `config/autocmds/*.lua` without a `config/autocmds.lua` isn't loaded by LazyVim.
local function load_user_config()
	local config_dir = vim.fn.stdpath('config') .. '/lua/config'
	local loaded_file = {} -- modules loaded by LazyVim
	local loaded_tree = {} -- directories (with `init.lua`) loaded by LazyVim

	for _, name in ipairs(LAZYVIM_USER_MODULES) do
		loaded_file[name] = vim.fn.filereadable(config_dir .. '/' .. name .. '.lua') == 1
		loaded_tree[name] = vim.fn.filereadable(config_dir .. '/' .. name .. '/init.lua') == 1
	end

	require('KoalaVim.utils.require_dir').require_abs(config_dir, 'config', {
		recursive = true,
		skip = function(module)
			if loaded_file[module] then
				return true
			end
			local top = module:match('^([^/]+)/')
			return top ~= nil and loaded_tree[top] == true
		end,
	})
end

-- `koala_init.load_lazy` sets `vim.g.koala_init_version`, an old `koala_init.lua` doesn't
local function warn_old_bootstrap()
	if vim.g.koala_init_version ~= nil then
		return
	end

	require('KoalaVim.health').warn(table.concat({
		'Old KoalaVim bootstrap detected, user config may load twice and your plugins load before LazyVim.',
		'To migrate (see https://github.com/KoalaVim/KoalaConfig.template):',
		'1. Update `lua/koala_init.lua` from the template.',
		"2. In `init.lua` remove `require_dir.recursive_require('config')` (KoalaVim loads your `config/` itself).",
		'3. In `init.lua` keep the `config_lazy` hook, then restart.',
	}, '\n'), true)
end

function M.init()
	if vim.env.KOALA_DEBUG_OUT then
		init_debug()
	else
		-- Disable debug
		DEBUG = function() end
	end

	vim.api.nvim_create_user_command('LazyRestoreLogged', function()
		local ret = require('KoalaVim.utils.restore').restore_logged()
		io.stderr:write(vim.json.encode(ret) .. '\n')
	end, {})

	-- Load kvim.conf before lazy.nvim resolves the specs, so specs can depend on it
	local conf = require('KoalaVim.conf')
	conf.load()
	conf.reg_autocmd()
	require('KoalaVim.state'):load()
	require('KoalaVim.flavor').get() -- validate flavor

	-- LazyVim's options override the leader keys that `koala_init.load_koala` set, restore them
	local leader, localleader = vim.g.mapleader, vim.g.maplocalleader
	vim.api.nvim_create_autocmd('User', {
		pattern = 'LazyVimOptionsDefaults',
		once = true,
		callback = function()
			vim.g.mapleader, vim.g.maplocalleader = leader, localleader
		end,
	})

	-- KoalaVim's layer on top of LazyVim's options/keymaps/autocmds, user's config is loaded by LazyVim afterwards.
	-- Registered before lazy.setup because LazyVim loads options while importing `lazyvim.plugins`.
	for _, name in ipairs(LAZYVIM_USER_MODULES) do
		vim.api.nvim_create_autocmd('User', {
			pattern = 'LazyVim' .. name:sub(1, 1):upper() .. name:sub(2) .. 'Defaults',
			once = true,
			callback = function()
				if name == 'options' then
					-- Options load while lazy.nvim imports `lazyvim.plugins`, KoalaVim isn't on the runtimepath yet
					vim.opt.rtp:prepend(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h'))
				end
				require('KoalaVim.config.' .. name)
			end,
		})
	end

	-- Rest of the user's config/ files, after the user's keymaps
	vim.api.nvim_create_autocmd('User', {
		pattern = 'LazyVimKeymaps',
		once = true,
		callback = load_user_config,
	})

	local rdir = require('KoalaVim.utils.require_dir')

	-- Lazy load config files
	vim.api.nvim_create_autocmd('User', {
		pattern = 'LazyVimStarted',
		callback = function()
			warn_old_bootstrap()

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
