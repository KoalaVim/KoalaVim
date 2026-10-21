-- Applies the contested-keys table (`KoalaVim.keymaps.contested`) to every place keys are defined.
--
--   LazyVim's keys                         entry point
--   -------------------------------------- ------------------------------------------------------------------
--   plugin spec `keys` (lazy.nvim)         `keys = remap.keys` (a `function(plugin, keys)` fragment)
--   LSP `opts.servers[*].keys`             `remap.servers(opts.servers)` / `remap.lsp_keys(list)`
--   global keymaps (`lazyvim.config...`)   `remap.snapshot()` + `remap.globals()` (wired in `KoalaVim.init()`)
--   `vim.keymap.set` in `on_attach`        `remap.on_attach(fn, bufnr_arg)` (rustaceanvim, gitsigns' LazyVim maps)
--
--   KoalaVim's own keys                    `kmap`/`kmap_buffer`/`kkeys`/`klhs` in `KoalaVim.utils.map`, built on
--                                          `remap.resolve()` below
--
-- Who loses a contested key depends on the active flavor (`KoalaVim.flavor`): in the `koala` flavor LazyVim's key is
-- moved/dropped, in the `lazyvim` flavor KoalaVim's. Entries with a fixed winner (`win`) apply in both flavors.
local M = {}

local flavor = require('KoalaVim.flavor')

--------------------------------------------------------------------------------------------------------------------
-- Key normalization
--------------------------------------------------------------------------------------------------------------------

local LEADER = '<leader>'

--- Canonical spelling of an lhs: `<leader>` stays symbolic, special keys use `keytrans` spelling
--- (`<A-j>` == `<M-j>`, `<S-h>` == `H`, `<c-w>` == `<C-W>`, `<S-Enter>` == `<S-CR>`).
---@param lhs string
---@return string
function M.canon(lhs)
	local ret = vim.fn.keytrans(vim.api.nvim_replace_termcodes(lhs, true, true, true))
	local leader = vim.fn.keytrans(vim.g.mapleader or '\\')
	if #ret > #leader and ret:sub(1, #leader) == leader then
		ret = LEADER .. ret:sub(#leader + 1)
	end
	return ret
end

local ALL_MODES = { 'n', 'x', 's', 'o', 'i', 'c', 't', 'l' }

--- Expands a `mode` (string or list, as accepted by `vim.keymap.set`) to single-letter modes.
--- `''`/`' '` = `nxso`, `v` = `xs`, `!` = `ic`.
---@param mode string|string[]|nil
---@return string[]
function M.modes(mode)
	if mode == nil then
		return { 'n' }
	end
	local ret, seen = {}, {}
	local function add(m)
		if not seen[m] then
			seen[m] = true
			ret[#ret + 1] = m
		end
	end
	for _, m in ipairs(type(mode) == 'table' and mode or { mode }) do
		if m == '' or m == ' ' then
			vim.tbl_map(add, { 'n', 'x', 's', 'o' })
		elseif m == 'v' then
			vim.tbl_map(add, { 'x', 's' })
		elseif m == '!' then
			vim.tbl_map(add, { 'i', 'c' })
		else
			-- `nx` style strings are not valid for `vim.keymap.set`, but be lenient
			for c in m:gmatch('.') do
				add(c == 'v' and 'x' or c)
			end
		end
	end
	return ret
end

---@param ft string|string[]|nil
---@return string[]|nil
local function ft_list(ft)
	if ft == nil then
		return nil
	end
	return type(ft) == 'table' and ft or { ft }
end

---@param rule_ft string[]|nil
---@param ft string[]|nil
---@return boolean
local function ft_match(rule_ft, ft)
	-- A rule without `ft` matches everything, a rule with `ft` only matches keys of those filetypes
	if rule_ft == nil then
		return true
	end
	if ft == nil then
		return false
	end
	for _, f in ipairs(rule_ft) do
		if vim.tbl_contains(ft, f) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------------------------------------------
-- Rule index (per active flavor)
--------------------------------------------------------------------------------------------------------------------

---@class KoalaVim.Keymaps.Rule
---@field modes table<string, true>
---@field ft? string[]
---@field to? string          canonical lhs
---@field drop? true|string
---@field entry KoalaVim.Keymaps.Entry

---@class KoalaVim.Keymaps.Index
---@field flavor 'koala'|'lazyvim'
---@field lazyvim table<string, KoalaVim.Keymaps.Rule[]>   canonical lhs -> rules for LazyVim's keys
---@field koala table<string, KoalaVim.Keymaps.Rule[]>     canonical lhs -> rules for KoalaVim's keys
---@field prefixes { lazyvim: table[], koala: table[] }    sorted, longest `from` first

---@type KoalaVim.Keymaps.Index?
local index

---@return KoalaVim.Keymaps.Index
local function get_index()
	local active = flavor.get()
	if index and index.flavor == active then
		return index
	end

	local contested = require('KoalaVim.keymaps.contested')
	index = { flavor = active, lazyvim = {}, koala = {}, prefixes = { lazyvim = {}, koala = {} } }

	for _, entry in ipairs(contested.entries) do
		local winner = entry.win or active
		local loser = winner == 'koala' and 'lazyvim' or 'koala'
		local side = entry[loser]
		if side and (side.to or side.drop) then
			local lhs = M.canon(entry[1])
			local rule = {
				modes = {},
				ft = ft_list(entry.ft),
				to = side.to and M.canon(side.to) or nil,
				drop = side.drop,
				entry = entry,
			}
			for _, m in ipairs(M.modes(side.mode or entry.mode)) do
				rule.modes[m] = true
			end
			index[loser][lhs] = index[loser][lhs] or {}
			table.insert(index[loser][lhs], rule)
		end
	end
	-- Rules with a filetype are more specific, check them first
	for _, side in ipairs({ 'lazyvim', 'koala' }) do
		for _, rules in pairs(index[side]) do
			table.sort(rules, function(a, b)
				return (a.ft ~= nil) and (b.ft == nil)
			end)
		end
	end

	for _, rule in ipairs(contested.prefixes) do
		-- the rules rewrite the keys of the flavor's loser
		local applies = (rule.side == 'lazyvim') == (active == 'koala')
		if applies then
			table.insert(index.prefixes[rule.side], {
				from = M.canon(rule.from),
				to = rule.to and M.canon(rule.to) or nil,
				drop = rule.drop,
				ft = ft_list(rule.ft),
			})
		end
	end
	for _, rules in pairs(index.prefixes) do
		table.sort(rules, function(a, b)
			return #a.from > #b.from
		end)
	end

	return index
end

--- Drop the cached index (tests that switch the flavor)
function M.reset()
	index = nil
end

--------------------------------------------------------------------------------------------------------------------
-- KoalaVim-owned keys
--------------------------------------------------------------------------------------------------------------------

-- Lazy key spec tables created by `kkeys()`, `remap.keys` leaves them alone (identity based, so it doesn't depend on
-- the position of the fragment that calls `remap.keys`)
---@type table<table, true>
local owned_specs = setmetatable({}, { __mode = 'k' })
-- `mode .. canonical lhs` of every key KoalaVim defined through `kmap`/`kkeys` that survived its flavor's rules
---@type table<string, true>
local owned_keys = {}

-- `mode .. canonical lhs` of the keys the engine moved LazyVim's actions to. They are final: sweeps must not apply
-- the rules of the key that used to be there (e.g. `<leader>st` -> `<leader>ft`, LazyVim's terminal `<leader>ft` is dropped)
---@type table<string, true>
local relocated = {}

---@param spec table
function M.own_spec(spec)
	owned_specs[spec] = true
	return spec
end

-- Global keymaps defined through `kmap`: `mode .. canonical lhs` -> definition. LazyVim's keymaps load on `VeryLazy` and
-- override whatever is on the key at that point, including a KoalaVim key that a plugin config defined earlier.
-- When the engine removes LazyVim's keymap it restores KoalaVim's.
---@type table<string, { mode: string, lhs: string, rhs: string|function, opts: table }>
local defs = {}

--- Remember a global keymap KoalaVim defined (see `kmap`)
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table  `vim.keymap.set` opts (with `desc`)
function M.remember(mode, lhs, rhs, opts)
	local canon = M.canon(lhs)
	for _, m in ipairs(M.modes(mode)) do
		defs[m .. canon] = { mode = m, lhs = lhs, rhs = rhs, opts = opts }
	end
end

---@param mode string|string[]|nil
---@param lhs string
function M.own(mode, lhs)
	local canon = M.canon(lhs)
	for _, m in ipairs(M.modes(mode)) do
		owned_keys[m .. canon] = true
	end
end

---@param mode string
---@param lhs string  canonical or not
---@return boolean
function M.is_owned(mode, lhs)
	return owned_keys[mode .. M.canon(lhs)] == true
end

--------------------------------------------------------------------------------------------------------------------
-- Rule lookup
--------------------------------------------------------------------------------------------------------------------

---@class KoalaVim.Keymaps.Action
---@field drop? true|string
---@field to? string        canonical lhs

--- What happens to a key of `side` in the active flavor. `nil`: untouched.
---@param side 'lazyvim'|'koala'
---@param canon string   canonical lhs
---@param mode string    single-letter mode
---@param ft string[]|nil
---@return KoalaVim.Keymaps.Action?
local function action_for(side, canon, mode, ft)
	local idx = get_index()
	for _, rule in ipairs(idx[side][canon] or {}) do
		if rule.modes[mode] and ft_match(rule.ft, ft) then
			return { to = rule.to, drop = rule.drop }
		end
	end

	-- Prefix rules, strictly longer keys only
	for _, rule in ipairs(idx.prefixes[side]) do
		if #canon > #rule.from and canon:sub(1, #rule.from) == rule.from and ft_match(rule.ft, ft) then
			if rule.to then
				return { to = rule.to .. canon:sub(#rule.from + 1) }
			end
			return { drop = rule.drop }
		end
	end
	return nil
end

---@param a KoalaVim.Keymaps.Action?
---@return string
local function outcome_id(a)
	if a == nil then
		return 'keep'
	end
	return a.to and ('to:' .. a.to) or 'drop'
end

--- Resolve a key to its final form(s) in the active flavor. A key defined for several modes can end up in several
--- groups (e.g. dropped in `n`, kept in `t`).
---@param side 'lazyvim'|'koala'  whose key it is
---@param lhs string
---@param mode string|string[]|nil
---@param ft string|string[]|nil
---@return { mode: string|string[], lhs: string, changed: boolean }[]  `lhs` is the original spelling when unchanged
function M.resolve_key(side, lhs, mode, ft)
	local canon = M.canon(lhs)
	local fts = ft_list(ft)
	local items = type(mode) == 'table' and mode or { mode == nil and 'n' or mode }

	---@type { id: string, mode: string[], lhs: string, changed: boolean }[]
	local groups = {}
	local by_id = {}
	local function push(id, m, new_lhs, changed)
		local g = by_id[id]
		if not g then
			g = { id = id, mode = {}, lhs = new_lhs, changed = changed }
			by_id[id] = g
			groups[#groups + 1] = g
		end
		table.insert(g.mode, m)
	end

	for _, item in ipairs(items) do
		local letters = M.modes(item)
		local actions, uniform = {}, true
		for i, m in ipairs(letters) do
			actions[i] = action_for(side, canon, m, fts)
			if i > 1 and outcome_id(actions[i]) ~= outcome_id(actions[1]) then
				uniform = false
			end
		end
		if uniform then
			local a = actions[1]
			push(outcome_id(a), item, a and a.to or lhs, a ~= nil and a.to ~= nil)
		else
			-- The mode spans keys with different fates, split it
			for i, m in ipairs(letters) do
				local a = actions[i]
				push(outcome_id(a), m, a and a.to or lhs, a ~= nil and a.to ~= nil)
			end
		end
	end

	local ret = {}
	for _, g in ipairs(groups) do
		if g.id ~= 'drop' then
			ret[#ret + 1] = { mode = #g.mode == 1 and g.mode[1] or g.mode, lhs = g.lhs, changed = g.changed }
		end
	end
	return ret
end

--- Resolve one of KoalaVim's keys, see `utils.map`'s `kmap`.
--- `lhs` is returned unchanged when KoalaVim wins, relocated for `lazyvim`'s flavor, and the key is absent from the
--- result when it's dropped.
---@param lhs string
---@param mode string|string[]|nil
---@param ft string|string[]|nil
---@return { mode: string|string[], lhs: string, changed: boolean }[]
function M.resolve(lhs, mode, ft)
	local groups = M.resolve_key('koala', lhs, mode, ft)
	for _, g in ipairs(groups) do
		M.own(g.mode, g.lhs)
	end
	return groups
end

--------------------------------------------------------------------------------------------------------------------
-- Plugin `keys` fragments / LSP keys
--------------------------------------------------------------------------------------------------------------------

---@param spec table
---@return table
local function copy_spec(spec)
	local ret = {}
	for k, v in pairs(spec) do
		ret[k] = v
	end
	return ret
end

--- lazy.nvim `keys` fragment: `keys = remap.keys`. Rewrites LazyVim's keys per the contested table, keeps `mode`,
--- `desc`, `ft`, `has`, `enabled` and every other field, and never touches keys created by KoalaVim (`kkeys`).
---
--- IMPORTANT: lazy.nvim runs a `keys` function with the keys of the fragments BEFORE it (and appends the keys of later
--- fragments untouched). Everything KoalaVim defines before the fragment must come from `kkeys` (or `kmap`), otherwise
--- it's treated as LazyVim's.
---@param plugin? table   unused, lazy.nvim passes the plugin
---@param keys? (string|table)[]
---@return (string|table)[]
function M.keys(plugin, keys)
	local ret = {}
	local idx = get_index()
	local koala_flavor = idx.flavor == 'koala'

	for _, key in ipairs(keys or {}) do
		local spec = type(key) == 'string' and { key } or key
		if owned_specs[spec] or type(spec[1]) ~= 'string' then
			ret[#ret + 1] = key
		else
			local groups = M.resolve_key('lazyvim', spec[1], spec.mode, spec.ft)
			-- KoalaVim wins every collision in the koala flavor, drop LazyVim's key if KoalaVim defines the same one
			local kept = {}
			for _, g in ipairs(groups) do
				if koala_flavor then
					local letters = M.modes(g.mode)
					local free = vim.tbl_filter(function(m)
						return not owned_keys[m .. M.canon(g.lhs)]
					end, letters)
					if #free == #letters then
						kept[#kept + 1] = g
					elseif #free > 0 then
						kept[#kept + 1] = { mode = #free == 1 and free[1] or free, lhs = g.lhs, changed = g.changed }
					end
				else
					kept[#kept + 1] = g
				end
			end

			if
				#kept == 1
				and not kept[1].changed
				and #groups == 1
				and vim.deep_equal(M.modes(kept[1].mode), M.modes(spec.mode))
			then
				ret[#ret + 1] = key -- untouched
			else
				for _, g in ipairs(kept) do
					if g.changed then
						for _, m in ipairs(M.modes(g.mode)) do
							relocated[m .. M.canon(g.lhs)] = true
						end
					end
					local c = copy_spec(spec)
					c[1] = g.lhs
					c.mode = g.mode
					ret[#ret + 1] = c
				end
			end
		end
	end
	return ret
end

--- Same as `keys` for the `keys` list of an LSP server (`opts.servers[name].keys`), `has`/`enabled` are preserved
---@param keys? (string|table)[]
---@return (string|table)[]
function M.lsp_keys(keys)
	return M.keys(nil, keys)
end

--- Apply `lsp_keys` to every server of `opts.servers` (nvim-lspconfig `opts`), modifies and returns `servers`
---@param servers? table<string, table|boolean>
---@return table<string, table|boolean>?
function M.servers(servers)
	for _, server in pairs(servers or {}) do
		if type(server) == 'table' and type(server.keys) == 'table' then
			server.keys = M.lsp_keys(server.keys)
		end
	end
	return servers
end

--------------------------------------------------------------------------------------------------------------------
-- Existing keymaps (global post-processor, `on_attach` wrapper)
--------------------------------------------------------------------------------------------------------------------

---@param map table  nvim_get_keymap() dict
---@return string
local function fingerprint(map)
	return table.concat({
		map.rhs or '',
		map.desc or '',
		map.callback and tostring(map.callback) or '',
		tostring(map.noremap),
		tostring(map.expr),
	}, '\0')
end

---@param buf integer?  nil: global keymaps
---@return table<string, string>  `mode .. lhs` -> fingerprint
local function snapshot_maps(buf)
	local ret = {}
	for _, mode in ipairs(ALL_MODES) do
		local maps = buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
		for _, map in ipairs(maps) do
			ret[map.mode .. map.lhs] = fingerprint(map)
		end
	end
	return ret
end

--- Source file of the function a keymap runs. bracket-repeat.nvim wraps the callback of every `[x`/`]x` keymap, look
--- through it (its `orig_cb` upvalue) to find the real owner.
---@param callback function
---@param depth? integer
---@return string?
local function callback_source(callback, depth)
	local info = debug.getinfo(callback, 'S')
	if not info or not info.source then
		return nil
	end
	if depth ~= 1 and info.source:find('bracket-repeat', 1, true) then
		local i = 1
		while true do
			local name, value = debug.getupvalue(callback, i)
			if not name then
				break
			end
			if name == 'orig_cb' and type(value) == 'function' then
				return callback_source(value, 1) or info.source
			end
			i = i + 1
		end
	end
	return info.source
end

---@param map table  nvim_get_keymap() dict
---@param pattern string  plain substring of the source file of the callback
---@return boolean
local function callback_from(map, pattern)
	if not map.callback then
		return false
	end
	local source = callback_source(map.callback)
	return source ~= nil and source:find(pattern, 1, true) ~= nil
end

--- Keymaps that never belong to LazyVim: KoalaVim's own, lazy.nvim's key stubs
---@param map table
---@return boolean
local function is_foreign(map)
	return callback_from(map, 'KoalaVim') or callback_from(map, 'lazy/core/handler/keys.lua')
end

--- Keymaps with a Lua callback defined in LazyVim (`lazyvim/plugins/...`, `lazyvim/util/...`)
---@param map table
---@return boolean
local function is_lazyvim_map(map)
	return callback_from(map, '/lua/lazyvim/')
end

---@param buf integer?  nil: global keymaps
---@param mode string
---@return table[]
local function get_maps(buf, mode)
	return buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
end

--- Rewrite the keymaps (`buf == nil`: global ones) that are new/changed since `before` per the contested table:
--- LazyVim's keys that lost are deleted or re-created on their new lhs (same rhs/callback/options).
---@param buf integer?
---@param before table<string, string>
---@param ft string[]|nil
---@param only_lazyvim? boolean  only touch keymaps with a callback defined in LazyVim (safe without a `before` snapshot)
---@return string[] issues
local function rewrite(buf, before, ft, only_lazyvim)
	local issues = {}
	local dels, sets = {}, {}
	local seen = {}
	for _, mode in ipairs(ALL_MODES) do
		for _, map in ipairs(get_maps(buf, mode)) do
			local id = map.mode .. map.lhs
			if
				not seen[id]
				and before[id] ~= fingerprint(map)
				and not (map.desc or ''):find('^which%-key%-trigger')
				and not is_foreign(map)
				and (not only_lazyvim or is_lazyvim_map(map))
			then
				seen[id] = true
				local letters = M.modes(map.mode)
				local canon = M.canon(map.lhs)
				local a = action_for('lazyvim', canon, letters[1], ft)
				-- A map has a single mode letter (or a group like `v`), all of them must agree
				for i = 2, #letters do
					if outcome_id(action_for('lazyvim', canon, letters[i], ft)) ~= outcome_id(a) then
						a = nil
						issues[#issues + 1] = ('mode group `%s` of `%s` has different fates'):format(map.mode, map.lhs)
					end
				end
				local key = letters[1] .. canon
				local def = not buf and defs[key] or nil
				if relocated[key] or (def and (def.opts.desc or '') == (map.desc or '')) then
					-- Moved by the engine already / KoalaVim's own keymap
					a = nil
				elseif owned_keys[key] then
					if only_lazyvim then
						-- LazyVim's map sits on a key KoalaVim owns, KoalaVim wins in the koala flavor
						if a == nil and flavor.get() == 'koala' then
							a = { drop = 'KoalaVim' }
						end
					elseif not def then
						-- Without a callback we can't tell LazyVim's keymaps from KoalaVim's: KoalaVim's own key
						-- replacing a lazy.nvim stub looks like a new keymap
						a = nil
					end
				end
				if a then
					dels[#dels + 1] = map
					if a.to then
						sets[#sets + 1] = { map = map, to = a.to }
					end
				end
			end
		end
	end

	for _, map in ipairs(dels) do
		pcall(vim.keymap.del, map.mode == ' ' and '' or map.mode, map.lhs, { buffer = buf })
		-- It replaced a KoalaVim key, which wins
		local def = not buf and defs[M.modes(map.mode)[1] .. M.canon(map.lhs)] or nil
		if def then
			vim.keymap.set(def.mode, def.lhs, def.rhs, vim.deepcopy(def.opts))
		end
	end

	for _, s in ipairs(sets) do
		local map = s.map
		local mode = map.mode == ' ' and '' or map.mode
		local clash = false
		for _, other in ipairs(get_maps(buf, M.modes(mode)[1])) do
			if M.canon(other.lhs) == s.to then
				clash = true
			end
		end
		if clash then
			issues[#issues + 1] = ('cannot move `%s` (%s) to `%s`, the key is taken'):format(
				map.lhs,
				map.desc or '',
				s.to
			)
		else
			for _, m in ipairs(M.modes(mode)) do
				relocated[m .. s.to] = true
			end
			vim.keymap.set(mode, s.to, map.callback or map.rhs or '', {
				desc = map.desc,
				buffer = buf,
				silent = map.silent == 1,
				expr = map.expr == 1,
				nowait = map.nowait == 1,
				script = map.script == 1,
				remap = map.noremap == 0,
				replace_keycodes = (map.expr == 1 and map.callback) and map.replace_keycodes == 1 or nil,
			})
		end
	end
	return issues
end

---@type table<string, string>?
local global_snapshot
---@type string[]
M.issues = {}

--- Record the global keymaps that exist before LazyVim's keymaps load (lazy.nvim key handlers, plugins loaded at
--- startup). Called on the first `User VeryLazy` by `KoalaVim.init()`.
function M.snapshot()
	global_snapshot = snapshot_maps(nil)
end

--- Rewrite LazyVim's global keymaps per the contested table and add the keys the flavor needs (`contested.adds`).
--- Called on `User LazyVimKeymapsDefaults`, before KoalaVim's own keymaps load.
--- Only keymaps created since `snapshot()` are touched, so lazy.nvim key stubs and KoalaVim's keys are safe.
---@return string[] issues
function M.globals()
	local issues = {}
	if global_snapshot then
		issues = rewrite(nil, global_snapshot, nil)
	else
		-- Without it KoalaVim's own and lazy.nvim's keys would look like LazyVim's
		issues[1] = "no keymaps snapshot, LazyVim's global keymaps are not rewritten"
	end

	for _, add in ipairs(require('KoalaVim.keymaps.contested').adds[get_index().flavor]) do
		local mode, lhs = add[1], add[2]
		local clash = false
		for _, m in ipairs(M.modes(mode)) do
			for _, other in ipairs(vim.api.nvim_get_keymap(m)) do
				if M.canon(other.lhs) == M.canon(lhs) then
					clash = true
				end
			end
		end
		if clash then
			issues[#issues + 1] = ('cannot add `%s` (%s), the key is taken'):format(lhs, add.desc)
		else
			vim.keymap.set(mode, lhs, add[3], { desc = add.desc, silent = true })
			M.own(mode, lhs)
		end
	end

	M.issues = issues
	for _, issue in ipairs(issues) do
		require('KoalaVim.health').warn('keymaps: ' .. issue)
	end

	-- LazyVim also defines keymaps later (plugin configs, ftplugins, LSP attach)
	M.watch()
	return issues
end

--- Rewrite the buffer-local keymaps that `fn` creates (see `on_attach`)
---@param buf integer
---@param before table<string, string>  from `M.snapshot_buffer`
---@return string[] issues
function M.rewrite_buffer(buf, before)
	local ft = vim.bo[buf].filetype
	return rewrite(buf, before, ft ~= '' and { ft } or nil)
end

---@param buf integer
---@return table<string, string>
function M.snapshot_buffer(buf)
	return snapshot_maps(buf)
end

--- Wrap an `on_attach` that creates LazyVim buffer-local keys with `vim.keymap.set` (rustaceanvim, gitsigns' LazyVim
--- maps): runs `fn` then rewrites the keys it created per the contested table.
---@generic T
---@param fn fun(...): T
---@param bufnr_arg? integer  position of the buffer number in the arguments of `fn` (default 1; rustaceanvim: 2)
---@return fun(...): T
function M.on_attach(fn, bufnr_arg)
	return function(...)
		local buf = select(bufnr_arg or 1, ...)
		if type(buf) ~= 'number' or not vim.api.nvim_buf_is_valid(buf) then
			return fn(...)
		end
		local before = M.snapshot_buffer(buf)
		local ret = fn(...)
		local issues = M.rewrite_buffer(buf, before)
		for _, issue in ipairs(issues) do
			require('KoalaVim.health').warn('keymaps: ' .. issue)
		end
		return ret
	end
end

--- Rewrite the keymaps of `buf` (`nil`: global) that LazyVim defines from Lua (e.g. in a plugin's `config`: illuminate's
--- `]]`/`[[`, rustaceanvim's `on_attach` keys) per the contested table. Safe at any time: only keymaps whose callback is
--- defined in LazyVim are touched.
---@param buf? integer
---@return string[] issues
function M.sweep(buf)
	if buf then
		if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
			return {}
		end
		local ft = vim.bo[buf].filetype
		return rewrite(buf, {}, ft ~= '' and { ft } or nil, true)
	end
	return rewrite(nil, {}, nil, true)
end

local watching = false

--- Sweep (see `sweep`) buffers on `FileType`/`LspAttach` and global keymaps whenever a plugin loads, after the event's
--- other handlers ran. Sweeps the existing buffers once. Wired by `KoalaVim.init()` after `globals()`.
function M.watch()
	if watching then
		return
	end
	watching = true

	local reported = {}
	local function run(buf)
		for _, issue in ipairs(M.sweep(buf)) do
			if not reported[issue] then
				reported[issue] = true
				table.insert(M.issues, issue)
				require('KoalaVim.health').warn('keymaps: ' .. issue)
			end
		end
	end
	-- LazyVim sets some keymaps asynchronously after the event (LSP keys), sweep again a bit later
	local pending = {}
	local function sweep(buf)
		local id = buf or 0
		if pending[id] then
			return
		end
		pending[id] = true
		vim.schedule(function()
			run(buf)
			for _, delay in ipairs({ 50, 300 }) do
				vim.defer_fn(function()
					run(buf)
					if delay == 300 then
						pending[id] = nil
					end
				end, delay)
			end
		end)
	end

	local group = vim.api.nvim_create_augroup('koala_keymaps_sweep', { clear = true })
	vim.api.nvim_create_autocmd({ 'FileType', 'LspAttach' }, {
		group = group,
		callback = function(ev)
			sweep(ev.buf)
		end,
	})
	vim.api.nvim_create_autocmd('User', {
		group = group,
		pattern = 'LazyLoad',
		callback = function()
			sweep(nil)
		end,
	})

	sweep(nil)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		sweep(buf)
	end
end

return M
