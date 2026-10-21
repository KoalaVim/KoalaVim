-- Verification of the keymaps of the active flavor (`KoalaVim.keymaps.check()`, `:checkhealth KoalaVim`):
--   1. no ambiguous prefixes: in the leader namespace no key is both a complete mapping and a strict prefix of another
--      mapping of the same mode (it would fire only after `timeoutlen`, and hijack what's typed next)
--   2. every contested key resolves to its flavor's winner and every relocated key sits on its new home
--      (`KoalaVim.keymaps.contested`)
local M = {}

local remap = require('KoalaVim.keymaps.remap')
local flavor = require('KoalaVim.flavor')

---@class KoalaVim.Keymaps.Violation
---@field kind 'ambiguous-prefix'|'wrong-winner'|'missing-winner'|'bad-relocation'|'missing-relocation'|'engine'
---@field flavor 'koala'|'lazyvim'
---@field mode? string
---@field lhs? string
---@field other? string[]   the longer keys (`ambiguous-prefix`) or the key of the other side
---@field buffer? integer   the violation is buffer-local
---@field msg string

---@class KoalaVim.Keymaps.CheckOpts
---@field bufnrs? integer[]   buffers to check besides the global keymaps (default: the current buffer). A scratch buffer
---                           with an LSP client and gitsigns attached covers the buffer-local keys.
---@field prefix? boolean     run the ambiguous-prefix check (default true)
---@field winners? boolean    run the contested-key check (default true)

local MODES = { 'n', 'x', 'o', 'i' }
local ALL_MODES = { 'n', 'x', 's', 'o', 'i', 'c', 't' }

---@param lhs string
---@return string[]
local function tokens(lhs)
	local ret = {}
	local i = 1
	while i <= #lhs do
		local close = lhs:sub(i, i) == '<' and lhs:find('>', i + 1, true) or nil
		if close and lhs:sub(i, close):match('^<[%w%-_]+>$') then
			ret[#ret + 1] = lhs:sub(i, close)
			i = close + 1
		else
			ret[#ret + 1] = lhs:sub(i, i)
			i = i + 1
		end
	end
	return ret
end

---@param map table  nvim_get_keymap() dict
---@return boolean
local function is_label(map)
	-- `{ '<leader>a', '', desc = '+ai' }`: group label for which-key, not a real mapping
	return (map.rhs == nil or map.rhs == '') and map.callback == nil
end

---@param map table
---@return boolean
local function is_noise(map)
	return (map.desc or ''):find('^which%-key%-trigger') ~= nil or is_label(map)
end

--- Keymaps in effect in `buf` (global ones, shadowed by the buffer-local ones), per canonical lhs
---@param buf integer?  nil: global keymaps only
---@param mode string
---@return table<string, table>   canonical lhs -> nvim_get_keymap() dict (buffer-local flagged `buffer == 1`)
local function effective(buf, mode)
	local ret = {}
	for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
		ret[remap.canon(map.lhs)] = map
	end
	if buf then
		for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
			ret[remap.canon(map.lhs)] = map
		end
	end
	return ret
end

---@param s string?
---@param sub string?
---@return boolean
local function has(s, sub)
	return s ~= nil and sub ~= nil and s:find(sub, 1, true) ~= nil
end

---@param map table
---@return string
local function describe(map)
	return ('%q'):format(map.desc or map.rhs or '')
end

--------------------------------------------------------------------------------------------------------------------
-- 1. Ambiguous prefixes
--------------------------------------------------------------------------------------------------------------------

---@param buf integer?
---@param out KoalaVim.Keymaps.Violation[]
---@param seen table<string, true>
local function check_prefixes(buf, out, seen)
	local contested = require('KoalaVim.keymaps.contested')
	local allowed = {}
	for _, a in ipairs(contested.allow_prefix) do
		allowed[a[1] .. remap.canon(a[2])] = true
	end

	local leader = vim.g.mapleader or '\\'
	for _, mode in ipairs(MODES) do
		local maps = effective(buf, mode)
		-- raw lhs of the leader namespace, sorted: the keys that extend a key follow it
		local lhss = {}
		for _, map in pairs(maps) do
			if map.lhs:sub(1, #leader) == leader and #map.lhs > #leader and not is_noise(map) then
				lhss[#lhss + 1] = map.lhs
			end
		end
		table.sort(lhss)

		local by_lhs = {}
		for _, map in pairs(maps) do
			by_lhs[map.lhs] = map
		end

		for i, short in ipairs(lhss) do
			local longer = {}
			for j = i + 1, #lhss do
				if lhss[j]:sub(1, #short) ~= short then
					break
				end
				longer[#longer + 1] = lhss[j]
			end
			local map = by_lhs[short]
			-- `nowait` keys never wait, they shadow the longer keys instead
			if #longer > 0 and not allowed[mode .. remap.canon(short)] then
				local id = mode .. short .. '\0' .. table.concat(longer, '\0')
				if not seen[id] then
					seen[id] = true
					local shown = vim.tbl_map(function(l)
						return l:gsub('^' .. vim.pesc(leader), '<leader>')
					end, vim.list_slice(longer, 1, 6))
					local name = short:gsub('^' .. vim.pesc(leader), '<leader>')
					out[#out + 1] = {
						kind = 'ambiguous-prefix',
						flavor = flavor.get(),
						mode = mode,
						lhs = name,
						other = shown,
						buffer = (map.buffer == 1 and buf) or nil,
						msg = ('%s `%s` (%s) is a prefix of %d key(s): %s%s'):format(
							mode,
							name,
							describe(map),
							#longer,
							table.concat(shown, ' '),
							#longer > #shown and ' ...' or ''
						),
					}
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------
-- 2. Contested keys
--------------------------------------------------------------------------------------------------------------------

---@param buf integer?
---@param out KoalaVim.Keymaps.Violation[]
local function check_winners(buf, out)
	local active = flavor.get()
	local ft = buf and vim.bo[buf].filetype or nil
	local effective_cache = {}
	local function eff(mode)
		effective_cache[mode] = effective_cache[mode] or effective(buf, mode)
		return effective_cache[mode]
	end

	local entries = require('KoalaVim.keymaps.contested').entries

	-- Keys that other entries relocate to: the same action moves there, don't mistake it for the loser staying put
	local targets = {}
	for _, entry in ipairs(entries) do
		local loser = (entry.win or active) == 'koala' and 'lazyvim' or 'koala'
		local side = entry[loser]
		if side and side.to then
			targets[remap.canon(side.to)] = true
		end
	end

	for _, entry in ipairs(entries) do
		local entry_fts = entry.ft and (type(entry.ft) == 'table' and entry.ft or { entry.ft }) or nil
		-- Filetype-scoped entries are buffer-local keys, only checked in buffers of those filetypes
		local winner = entry.win or active
		local loser = winner == 'koala' and 'lazyvim' or 'koala'
		local win_side, lose_side = entry[winner], entry[loser]
		-- An entry that only lists the winner has nothing to verify (the loser's side is unknown)
		if lose_side and (entry_fts == nil or (ft and vim.tbl_contains(entry_fts, ft))) then
			local canon = remap.canon(entry[1])
			local to = lose_side.to and remap.canon(lose_side.to) or nil

			-- The modes each side binds the key in (default: the entry's)
			local win_modes = remap.modes(win_side and win_side.mode or entry.mode)
			local lose_modes = remap.modes(lose_side.mode or entry.mode)
			local modes = vim.fn.uniq(vim.fn.sort(vim.list_extend(vim.list_slice(win_modes), lose_modes)))

			for _, mode in ipairs(modes) do
				if vim.tbl_contains(ALL_MODES, mode) then
					local in_win, in_lose = vim.tbl_contains(win_modes, mode), vim.tbl_contains(lose_modes, mode)
					local actual = eff(mode)[canon]
					local function report(kind, msg, other)
						out[#out + 1] = {
							kind = kind,
							flavor = active,
							mode = mode,
							lhs = entry[1],
							other = other,
							buffer = buf,
							msg = ('%s `%s`: %s'):format(mode, entry[1], msg),
						}
					end

					if actual then
						local is_loser = in_lose and not targets[canon] and has(actual.desc, lose_side.desc)
						local is_winner = in_win and win_side and has(actual.desc, win_side.desc)
						if is_loser and not is_winner then
							report(
								'wrong-winner',
								('%s owns it (%s), %s should'):format(loser, describe(actual), winner)
							)
						elseif
							in_win
							and win_side
							and win_side.desc
							and not is_winner
							and not is_loser
							and (actual.desc or '') ~= ''
						then
							report(
								'wrong-winner',
								("expected %s's %q, found %s"):format(winner, win_side.desc, describe(actual))
							)
						end
					elseif in_win and win_side and win_side.desc and not win_side.optional then
						report('missing-winner', ("%s's %q is not bound"):format(winner, win_side.desc))
					end

					-- The loser's action sits on its new home
					if in_lose and to and lose_side.desc then
						local moved = eff(mode)[to]
						if moved and not has(moved.desc, lose_side.desc) then
							report(
								'bad-relocation',
								('%q should move to `%s`, which is %s'):format(
									lose_side.desc,
									lose_side.to,
									describe(moved)
								),
								{ lose_side.to }
							)
						elseif not moved and not lose_side.optional then
							report(
								'missing-relocation',
								('%q should move to `%s`, which is unbound'):format(lose_side.desc, lose_side.to),
								{ lose_side.to }
							)
						end
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------

--- Verify the keymaps of the active flavor, returns the list of violations (empty: all good).
---@param opts? KoalaVim.Keymaps.CheckOpts
---@return KoalaVim.Keymaps.Violation[]
function M.run(opts)
	opts = opts or {}
	local out = {}
	local bufs = opts.bufnrs or { vim.api.nvim_get_current_buf() }

	for _, issue in ipairs(remap.issues) do
		out[#out + 1] = { kind = 'engine', flavor = flavor.get(), msg = issue }
	end

	local seen = {}
	-- the buffer checks include the global keymaps, don't report those twice
	local reported = {}
	local function collect(fn, buf)
		local list = {}
		fn(buf, list, seen)
		for _, v in ipairs(list) do
			local id = v.kind .. (v.mode or '') .. (v.lhs or '') .. v.msg
			if not reported[id] then
				reported[id] = true
				out[#out + 1] = v
			end
		end
	end

	if opts.prefix ~= false then
		collect(check_prefixes, nil)
		for _, buf in ipairs(bufs) do
			collect(check_prefixes, buf)
		end
	end
	if opts.winners ~= false then
		collect(check_winners, nil)
		for _, buf in ipairs(bufs) do
			collect(check_winners, buf)
		end
	end
	return out
end

return M
