local M = {}

local PATTERN = { '.kvim.conf', 'default_kvim.conf' }
local json_file = require('KoalaVim.utils.json_file')

function M.get_repo_conf()
	local output = vim.fn.system("git rev-parse --show-toplevel | tr -d '\\n'")
	if output:find('fatal: ') then
		return nil
	end
	return output .. '/.kvim.conf'
end

function M.get_user_conf()
	if vim.env.KOALA_KVIM_CONF then -- prioritize `kv` conf
		return vim.env.KOALA_KVIM_CONF
	end
	return vim.fn.expand('$HOME') .. '/.kvim.conf'
end

local function _get_kvim_dir()
	local info = debug.getinfo(1, 'S')
	local curr_path = string.match(info.source, '^@(.*)')

	return curr_path:gsub('lua/KoalaVim/conf.lua', '')
end

function M.get_kvim_conf()
	return _get_kvim_dir() .. '/default_kvim.conf'
end

function M.reg_autocmd()
	vim.api.nvim_create_autocmd('BufEnter', {
		pattern = PATTERN,
		callback = function(events)
			vim.api.nvim_buf_set_option(events.buf, 'filetype', 'json')
		end,
	})
end

function M.get_scheme()
	return {
		description = 'KoalaVim config',
		fileMatch = PATTERN,
		name = 'KoalaVim',
		url = _get_kvim_dir() .. '/config_scheme.jsonc',
	}
end

local function _verify(opts_tbl, scope_string)
	local valid = true
	for key, value in pairs(opts_tbl) do
		if type(value) == 'table' then
			_verify(value, scope_string and scope_string .. key .. '.' or nil)
		else
			if value == vim.NIL then
				if scope_string then
					-- TODO: better warnings
					-- stylua: ignore
					print(scope_string .. key .. " isn't configured (you can turn off this message by passing `warnings = false` in koala opts)")
					valid = false
				else
					-- If warnings aren't on just return return false
				end
			end
		end
	end

	return valid
end

function M.verify(opts_tbl)
	return _verify(opts_tbl, nil)
end

function M.load()
	local default = json_file.load(M.get_kvim_conf(), false)
	local user = json_file.load(M.get_user_conf(), true)
	local git = json_file.load(M.get_repo_conf(), false)
	local conf = vim.tbl_deep_extend('keep', git, user, default)

	-- TODO: show config verification warnings in the dashboard
	-- _verify(conf, '')
	require('KoalaVim').conf = conf
end

return M
