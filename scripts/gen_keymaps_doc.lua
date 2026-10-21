-- Generates the per-flavor keymap cheat sheet (docs/keymaps.md) from lua/KoalaVim/keymaps/contested.lua
-- and the which-key groups of lua/KoalaVim/plugins/lazyvim_keys.lua.
-- Usage: nvim -l scripts/gen_keymaps_doc.lua

local script_dir = debug.getinfo(1, 'S').source:match('@(.*/)') or './'
local root = script_dir .. '../'
local output_path = root .. 'docs/keymaps.md'

package.path = root .. 'lua/?.lua;' .. root .. 'lua/?/init.lua;' .. package.path
local contested = require('KoalaVim.keymaps.contested')

---@param path string
---@return string
local function read(path)
	local f = assert(io.open(path, 'r'))
	local raw = f:read('*a')
	f:close()
	return raw
end

--- `{ lhs, group }` pairs of a `local <name> = { ... }` table in lazyvim_keys.lua (a column-0 closing brace ends it)
---@param src string
---@param name string
---@return { [1]: string, [2]: string }[]
local function parse_groups(src, name)
	local body = src:match('\nlocal ' .. name .. ' = {\n(.-)\n}\n')
	assert(body, 'cannot find `' .. name .. '` in lazyvim_keys.lua')
	local ret = {}
	for lhs, group in body:gmatch("{ '([^']+)', '([^']+)' }") do
		ret[#ret + 1] = { lhs, group }
	end
	return ret
end

local keys_src = read(root .. 'lua/KoalaVim/plugins/lazyvim_keys.lua')
local koala_groups = parse_groups(keys_src, 'koala_groups')
local lazyvim_groups = parse_groups(keys_src, 'lazyvim_groups')

--------------------------------------------------------------------------------------------------------------------
-- Markdown helpers
--------------------------------------------------------------------------------------------------------------------

---@param s string
---@return string
local function code(s)
	s = s:gsub('|', '\\|')
	if s:find('`', 1, true) then
		return '`` ' .. s .. ' ``'
	end
	return '`' .. s .. '`'
end

---@param s string?
---@return string
local function text(s)
	s = (s or ''):gsub('|', '\\|'):gsub('`', '\\`')
	-- Keys with special notation (`<leader>gs`) are code, a bare `<` would be taken as HTML
	return (s:gsub('%S*<%S*', function(token)
		return '`' .. token:gsub('\\([`|])', '%1') .. '`'
	end))
end

---@param v string|string[]|nil
---@return string[]
local function list(v)
	if v == nil then
		return {}
	end
	return type(v) == 'table' and v or { v }
end

---@param modes string|string[]|nil
---@return string
local function modes_str(modes)
	local m = list(modes)
	if #m == 0 then
		return 'n'
	end
	return table.concat(m, ',')
end

--- Keys named as `drop` targets (`<leader>cf`, `]c`, `<F2>`) are code, everything else is a note ("vim default")
---@param s string
---@return boolean
local function looks_like_key(s)
	return not s:find(' ', 1, true) and (s:find('^<') ~= nil or #s <= 3 or s:find('^[%[%]g]') ~= nil)
end

---@param side table
---@return string
local function result(side)
	if side.to then
		return 'moved to ' .. code(side.to)
	elseif type(side.drop) == 'string' then
		if looks_like_key(side.drop) then
			return 'dropped, use ' .. code(side.drop)
		end
		return 'dropped (' .. text(side.drop) .. ')'
	end
	return 'dropped'
end

--------------------------------------------------------------------------------------------------------------------
-- Rows
--------------------------------------------------------------------------------------------------------------------

---@class gen.Row
---@field key string
---@field mode string
---@field was string
---@field now string
---@field result string

--- Rows of the entries where `owner`'s binding of the key loses in `flavor`
---@param flavor 'koala'|'lazyvim'
---@param owner 'koala'|'lazyvim'
---@return gen.Row[]
local function rows_of(flavor, owner)
	local rows = {}
	for _, entry in ipairs(contested.entries) do
		local winner = entry.win or flavor
		local loser = winner == 'koala' and 'lazyvim' or 'koala'
		local side = entry[loser]
		if loser == owner and side and (side.to or side.drop) then
			local win_side = entry[winner]
			local key = code(entry[1])
			if entry.ft then
				key = key .. ' (' .. table.concat(list(entry.ft), ',') .. ')'
			end
			rows[#rows + 1] = {
				key = key,
				mode = modes_str(side.mode or entry.mode),
				was = text(side.desc),
				now = win_side and text(win_side.desc) or '',
				result = result(side),
			}
		end
	end
	return rows
end

---@param out string[]
---@param rows gen.Row[]
local function emit_rows(out, rows)
	if #rows == 0 then
		out[#out + 1] = '_None._'
		out[#out + 1] = ''
		return
	end
	out[#out + 1] = '| Key | Mode | Action | Key now does | Result |'
	out[#out + 1] = '| --- | --- | --- | --- | --- |'
	for _, r in ipairs(rows) do
		out[#out + 1] = ('| %s | %s | %s | %s | %s |'):format(r.key, r.mode, r.was, r.now, r.result)
	end
	out[#out + 1] = ''
end

---@param out string[]
---@param flavor 'koala'|'lazyvim'
local function emit_prefixes(out, flavor)
	local rule_side = flavor == 'koala' and 'lazyvim' or 'koala'
	local rules = vim.tbl_filter(function(r)
		return r.side == rule_side
	end, contested.prefixes)
	if #rules == 0 then
		out[#out + 1] = '_None._'
		out[#out + 1] = ''
		return
	end
	out[#out + 1] = ('| %s keys under | Result |'):format(rule_side == 'koala' and 'KoalaVim' or 'LazyVim')
	out[#out + 1] = '| --- | --- |'
	for _, r in ipairs(rules) do
		local res
		if r.to then
			res = 'moved under ' .. code(r.to .. '*')
		elseif type(r.drop) == 'string' then
			res = 'dropped (' .. text(r.drop) .. ')'
		else
			res = 'dropped'
		end
		local from = code(r.from .. '*')
		if r.ft then
			from = from .. ' (' .. table.concat(list(r.ft), ',') .. ')'
		end
		out[#out + 1] = ('| %s | %s |'):format(from, res)
	end
	out[#out + 1] = ''
end

---@param out string[]
---@param flavor 'koala'|'lazyvim'
local function emit_adds(out, flavor)
	local adds = contested.adds[flavor] or {}
	if #adds == 0 then
		out[#out + 1] = '_None._'
		out[#out + 1] = ''
		return
	end
	out[#out + 1] = '| Key | Mode | Action |'
	out[#out + 1] = '| --- | --- | --- |'
	for _, add in ipairs(adds) do
		out[#out + 1] = ('| %s | %s | %s |'):format(code(add[2]), modes_str(add[1]), text(add.desc))
	end
	out[#out + 1] = ''
end

--------------------------------------------------------------------------------------------------------------------
-- Document
--------------------------------------------------------------------------------------------------------------------

-- LazyVim's own groups (what the `lazyvim` flavor keeps), see `lazyvim.plugins.editor` (which-key spec)
local lazyvim_layout = {
	{ '<leader><tab>', 'tabs' },
	{ '<leader>b', 'buffer' },
	{ '<leader>c', 'code' },
	{ '<leader>d', 'debug' },
	{ '<leader>dp', 'profiler' },
	{ '<leader>f', 'file/find' },
	{ '<leader>g', 'git' },
	{ '<leader>gh', 'hunks' },
	{ '<leader>q', 'quit/session' },
	{ '<leader>s', 'search' },
	{ '<leader>u', 'ui' },
	{ '<leader>w', 'windows' },
	{ '<leader>x', 'diagnostics/quickfix' },
}

---@param groups { [1]: string, [2]: string }[]
---@return string
local function groups_inline(groups)
	local parts = {}
	for _, g in ipairs(groups) do
		parts[#parts + 1] = code(g[1]) .. ' ' .. g[2]
	end
	return table.concat(parts, ', ')
end

local out = {
	'<!-- Generated from lua/KoalaVim/keymaps/contested.lua - do not edit manually. -->',
	'<!-- Run: make gen-keymaps-doc (nvim -l scripts/gen_keymaps_doc.lua) -->',
	'',
	'# Keymaps per flavor',
	'',
	'KoalaVim runs on top of LazyVim, both bind keys. The `flavor` option (`~/.kvim.conf`, `{"flavor": "koala" | "lazyvim"}`)',
	'decides who owns a contested key; the loser is moved or dropped. This sheet lists, per flavor, what moved, what was',
	'dropped and what KoalaVim adds. Source of truth: [`contested.lua`](../lua/KoalaVim/keymaps/contested.lua), verified',
	'by `require("KoalaVim.keymaps").check()` (`make test-keymaps`, `:checkhealth KoalaVim`).',
	'',
	'`<leader>` is `<space>`. A key listed once with a moved/dropped result is not bound to the original action anymore.',
	'',
	'## Group prefixes',
	'',
	'| Prefix | `koala` flavor | `lazyvim` flavor |',
	'| --- | --- | --- |',
}

-- Union of all group lhs, in a stable order
local function group_name(groups, lhs)
	for _, g in ipairs(groups) do
		if g[1] == lhs then
			return g[2]
		end
	end
end

local koala_layout = {
	{ '<leader>c', 'change without yanking (operator)' },
	{ '<leader>d', 'delete without yanking (operator)' },
	{ '<leader>s', 'spell fixer' },
	{ '<leader>b', 'build & deploy' },
	{ '<leader>v', 'code' },
	{ '<leader>r', 'run/debug' },
	{ '<leader>f', "find/search (LazyVim's `<leader>s*` merged in)" },
	{ '<leader>q', "quit/buffers (LazyVim's `<leader>b*` merged in)" },
	{ '<leader>z', 'lazy' },
	{ '<leader>g', 'git' },
	{ '<leader>u', 'ui' },
	{ '<leader>x', 'diagnostics/quickfix' },
}
for _, g in ipairs(koala_groups) do
	if not group_name(koala_layout, g[1]) then
		koala_layout[#koala_layout + 1] = g
	end
end

local lv_full = vim.deepcopy(lazyvim_layout)
vim.list_extend(lv_full, {
	{ '<leader>C', 'change without yanking (operator)' },
	{ '<leader>D', 'delete without yanking (operator)' },
})
for _, g in ipairs(lazyvim_groups) do
	if not group_name(lv_full, g[1]) then
		lv_full[#lv_full + 1] = g
	end
end

local lhs_seen, lhs_order = {}, {}
for _, g in ipairs(koala_layout) do
	if not lhs_seen[g[1]] then
		lhs_seen[g[1]] = true
		lhs_order[#lhs_order + 1] = g[1]
	end
end
for _, g in ipairs(lv_full) do
	if not lhs_seen[g[1]] then
		lhs_seen[g[1]] = true
		lhs_order[#lhs_order + 1] = g[1]
	end
end
table.sort(lhs_order)
for _, lhs in ipairs(lhs_order) do
	out[#out + 1] = ('| %s | %s | %s |'):format(
		code(lhs),
		group_name(koala_layout, lhs) or '-',
		group_name(lv_full, lhs) or '-'
	)
end
vim.list_extend(out, {
	'',
	"- **koala**: KoalaVim's layout. LazyVim's code group `<leader>c` moves to `<leader>v`, debug `<leader>d` to",
	'  `<leader>r`, buffers `<leader>b` to `<leader>q`, search `<leader>s` merges into `<leader>f`, and its lazy keys',
	"  (`<leader>l`, ...) to `<leader>z`. `<leader>c`, `<leader>d` and `<leader>s` are KoalaVim's black-hole change /",
	'  delete and spell fixer.',
	"- **lazyvim**: LazyVim's layout is intact. KoalaVim keys that sit under a LazyVim single key move into a family",
	'  next to it (`<leader>fc*` to `<leader>fC*`, `<leader>fn*` to `<leader>fN*`, Octo to `<leader>gO*`, build / deploy to',
	'  `<leader>r*`).',
	'',
	('Which-key groups KoalaVim registers: **koala** %s; **lazyvim** %s.'):format(
		groups_inline(koala_groups),
		groups_inline(lazyvim_groups)
	),
	'',
})

for _, flavor in ipairs({ 'koala', 'lazyvim' }) do
	local other = flavor == 'koala' and 'LazyVim' or 'KoalaVim'
	local own = flavor == 'koala' and 'KoalaVim' or 'LazyVim'
	vim.list_extend(out, {
		('## `%s` flavor'):format(flavor),
		'',
		("%s wins contested keys; %s's bindings are moved or dropped."):format(own, other),
		'',
		('### %s keys moved or dropped'):format(other),
		'',
	})
	emit_rows(out, rows_of(flavor, flavor == 'koala' and 'lazyvim' or 'koala'))

	local loser_owner = flavor == 'koala' and 'koala' or 'lazyvim'
	local pinned = rows_of(flavor, loser_owner)
	if #pinned > 0 then
		vim.list_extend(out, {
			('### %s keys that lose to %s anyway'):format(own, other),
			'',
			'Entries whose owner is pinned in both flavors (`win` in `contested.lua`).',
			'',
		})
		emit_rows(out, pinned)
	end

	vim.list_extend(out, {
		('### %s key families (prefix rules)'):format(other),
		'',
		'Every key longer than the prefix is rewritten (explicit rows above take precedence).',
		'',
	})
	emit_prefixes(out, flavor)

	vim.list_extend(out, {
		'### Keys added',
		'',
		flavor == 'koala' and "Keys LazyVim had that KoalaVim's layout would have lost."
			or "KoalaVim features that need a key in LazyVim's layout.",
		'',
	})
	emit_adds(out, flavor)
end

while out[#out] == '' do
	out[#out] = nil
end

local f = assert(io.open(output_path, 'w'))
f:write(table.concat(out, '\n') .. '\n')
f:close()

print('Generated ' .. output_path)
