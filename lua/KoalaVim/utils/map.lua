local M = {}

local default_opts = { silent = true }
local function map(mode, l, r, desc, opts)
	opts = opts or default_opts
	opts.desc = desc
	opts.buffer = nil
	vim.keymap.set(mode, l, r, opts)
end

local function map_buffer(bufid, mode, l, r, desc, opts)
	opts = opts or default_opts
	opts.buffer = bufid
	opts.desc = desc
	vim.keymap.set(mode, l, r, opts)
end

M.map = map
M.map_buffer = map_buffer

--------------------------------------------------------------------------------------------------------------------
-- Flavor-aware variants, for keys that are listed in `KoalaVim.keymaps.contested` (contested with LazyVim's keys or
-- duplicates of its actions). Under the `koala` flavor they behave exactly like their plain counterparts. Under the
-- `lazyvim` flavor a key is skipped when LazyVim has the same action on another key, and relocated to its new home
-- when LazyVim owns the key.
--
-- Keys that aren't in the table are defined as is, so using these is always safe.
--------------------------------------------------------------------------------------------------------------------

---@param opts table?
---@return table
local function copy_opts(opts)
	return vim.deepcopy(opts or default_opts)
end

--- `map()` that skips/relocates the key per the active flavor
---@param mode string|string[]
---@param l string
---@param r string|function
---@param desc string?
---@param opts? table  `vim.keymap.set` opts, `ft` (string|string[]) selects filetype-scoped contested entries
function M.kmap(mode, l, r, desc, opts)
	opts = copy_opts(opts)
	local ft = opts.ft
	opts.ft = nil
	local remap = require('KoalaVim.keymaps.remap')
	for _, key in ipairs(remap.resolve(l, mode, ft)) do
		map(key.mode, key.lhs, r, desc, copy_opts(opts))
		remap.remember(key.mode, key.lhs, r, vim.tbl_extend('force', copy_opts(opts), { desc = desc }))
	end
end

--- `map_buffer()` that skips/relocates the key per the active flavor; the filetype of the buffer selects
--- filetype-scoped contested entries
---@param bufid integer
---@param mode string|string[]
---@param l string
---@param r string|function
---@param desc string?
---@param opts? table
function M.kmap_buffer(bufid, mode, l, r, desc, opts)
	opts = copy_opts(opts)
	local ft = opts.ft or (vim.api.nvim_buf_is_valid(bufid) and vim.bo[bufid].filetype or nil)
	opts.ft = nil
	for _, key in ipairs(require('KoalaVim.keymaps.remap').resolve(l, mode, ft ~= '' and ft or nil)) do
		map_buffer(bufid, key.mode, key.lhs, r, desc, copy_opts(opts))
	end
end

--- Flavor-aware lazy.nvim `keys` list: `keys = kkeys({ { '<leader>gs', fn, desc = '...' }, ... })`.
--- Returns new specs (a key can end up with a different lhs, in a subset of its modes, or be removed). The returned
--- specs are registered as KoalaVim's, `remap.keys` never rewrites them.
---@param keys (string|table)[]
---@return table[]
function M.kkeys(keys)
	local remap = require('KoalaVim.keymaps.remap')
	local ret = {}
	for _, key in ipairs(keys) do
		local spec = type(key) == 'string' and { key } or key
		if type(spec[1]) ~= 'string' or spec[2] == false then
			-- `{ lhs, false }` removes the key of another spec (LazyVim's), it's not one of ours: `remap.keys` treats it like
			-- the key it removes
			ret[#ret + 1] = key
		else
			for _, resolved in ipairs(remap.resolve(spec[1], spec.mode, spec.ft)) do
				local copy = {}
				for k, v in pairs(spec) do
					copy[k] = v
				end
				copy[1] = resolved.lhs
				if spec.mode ~= nil or resolved.changed or type(resolved.mode) == 'table' then
					copy.mode = resolved.mode
				end
				ret[#ret + 1] = remap.own_spec(copy)
			end
		end
	end
	return ret
end

--- Final lhs of a KoalaVim key under the active flavor (hydra bodies, tables of keys): `nil` when the key is dropped.
--- For a key defined in several modes with different fates the lhs of the first surviving mode group is returned.
---@param lhs string
---@param mode? string|string[]  default `n`
---@param ft? string|string[]
---@return string?
function M.klhs(lhs, mode, ft)
	local keys = require('KoalaVim.keymaps.remap').resolve(lhs, mode, ft)
	return keys[1] and keys[1].lhs or nil
end

return M
