-- Contested keys: every key that LazyVim and KoalaVim both bind (or that LazyVim binds on a vim default), and what
-- happens to it in each flavor. This table is the single source for the engine (`KoalaVim.keymaps.remap`), the `kmap()`
-- helper (`KoalaVim.utils.map`) and the verification (`KoalaVim.keymaps.check`).
--
-- Model
-- -----
-- One key (`lhs` + `mode`) can have two bindings, a LazyVim one and a KoalaVim one. The active flavor decides who wins
-- (`koala` flavor: KoalaVim, `lazyvim` flavor: LazyVim), `win` pins the winner for both flavors. The loser's binding
-- moves (`to`) or is removed (`drop`). A `Side` describes what happens to ITS key when it loses, so:
--   * `lazyvim = { to/drop }` is applied to LazyVim's key in the `koala` flavor,
--   * `koala   = { to/drop }` is applied to KoalaVim's key in the `lazyvim` flavor.
-- A side without `to`/`drop` is only used to identify the owner (`desc`) in `check()`.
--
-- Notation: `<leader>` for the leader key, any spelling of special keys (`<A-j>` == `<M-j>`, `<S-h>` == `H`),
-- see `remap.canon()`.

---@class KoalaVim.Keymaps.Side
---@field desc? string        substring of the mapping's `desc`, tells who owns the key at runtime (`check()`)
---@field to? string          when this side loses, its action moves to this lhs
---@field drop? true|string   when this side loses, it is removed; a string names the key that already does the same
---@field optional? boolean   the key may legitimately be unbound (plugin, capability or filetype gated), `check()` doesn't complain
---@field mode? string|string[]  the modes this side binds the key in (default: the entry's `mode`)

---@class KoalaVim.Keymaps.Entry
---@field [1] string                       lhs
---@field mode? string|string[]            default `n`
---@field ft? string|string[]              the entry only applies to keys of these filetypes (e.g. `rust` buffer-local keys)
---@field win? 'koala'|'lazyvim'           fixed winner in both flavors (default: the active flavor)
---@field lazyvim? KoalaVim.Keymaps.Side   LazyVim's binding of the key
---@field koala? KoalaVim.Keymaps.Side     KoalaVim's binding of the key

---@class KoalaVim.Keymaps.PrefixRule
---@field side 'lazyvim'|'koala'   whose keys are rewritten: `lazyvim` in the koala flavor, `koala` in the lazyvim flavor
---@field from string              every lhs STRICTLY longer than `from` (and starting with it) is affected
---@field to? string               the prefix is replaced by `to`
---@field drop? true|string        the keys are removed
---@field ft? string|string[]

---@class KoalaVim.Keymaps.Add
---@field [1] string|string[]       mode
---@field [2] string                lhs
---@field [3] string|function       rhs
---@field desc string

---@type KoalaVim.Keymaps.Entry[]
local entries = {}

---@param lhs string
---@param spec table
local function e(lhs, spec)
	spec[1] = lhs
	entries[#entries + 1] = spec
end

-- Shorthands for the common one-sided shapes. `extra` carries `mode`/`ft`/`win` of the entry and `optional` of the side.
---@param lhs string
---@param side_name 'lazyvim'|'koala'
---@param side KoalaVim.Keymaps.Side
---@param extra? { mode?: string|string[], ft?: string|string[], optional?: boolean }
local function one_sided(lhs, side_name, side, extra)
	extra = extra and vim.deepcopy(extra) or {}
	side.optional = extra.optional
	extra.optional = nil
	extra[side_name] = side
	e(lhs, extra)
end

-- LazyVim's key that is removed (`drop`) or moved (`to`) in the koala flavor, KoalaVim has no binding on it
---@param lhs string
---@param desc string?
---@param act string|true  `true` or the key that already does the same
---@param extra? table
local function lv_drop(lhs, desc, act, extra)
	one_sided(lhs, 'lazyvim', { desc = desc, drop = act }, extra)
end

---@param lhs string
---@param desc string?
---@param to string
---@param extra? table
local function lv_move(lhs, desc, to, extra)
	one_sided(lhs, 'lazyvim', { desc = desc, to = to }, extra)
end

-- KoalaVim's key that is removed/moved in the lazyvim flavor
---@param lhs string
---@param desc string?
---@param act string|true
---@param extra? table
local function kv_drop(lhs, desc, act, extra)
	one_sided(lhs, 'koala', { desc = desc, drop = act }, extra)
end

---@param lhs string
---@param desc string?
---@param to string
---@param extra? table
local function kv_move(lhs, desc, to, extra)
	one_sided(lhs, 'koala', { desc = desc, to = to }, extra)
end

local OPT = { optional = true }

--------------------------------------------------------------------------------------------------------------------
-- A. Hard collisions: same key, different action
--------------------------------------------------------------------------------------------------------------------

e('<leader>l', {
	lazyvim = { desc = 'Lazy', to = '<leader>zz' },
	koala = { desc = 'Cycle between lsp diagnostics mode', to = '<leader>uv' },
})
e('<leader>L', {
	lazyvim = { desc = 'LazyVim Changelog', to = '<leader>zl' },
	koala = { desc = 'show Problem', drop = '<leader>cd' },
})
e('<leader>qq', {
	lazyvim = { desc = 'Quit All', to = '<leader>qQ' },
	koala = { desc = 'Close current tab', drop = '<leader>bd' },
})
e('<leader>,', {
	lazyvim = { desc = 'Buffers', drop = '<leader>fb' },
	koala = { desc = 'Previous tabpage', drop = '<leader><tab>[', mode = { 'n', 'v' } },
})
e('<leader>.', {
	lazyvim = { desc = 'Toggle Scratch Buffer', drop = '<leader>S' },
	koala = { desc = 'Next tabpage', drop = '<leader><tab>]', mode = { 'n', 'v' } },
})
e('<leader>`', {
	lazyvim = { desc = 'Switch to Other Buffer', drop = '<leader><Tab>' },
	koala = { desc = 'Replace surround to `', drop = true },
})
-- Both flavors: LazyVim's `<leader>ud` (toggle diagnostics). KoalaVim's dim toggle is LazyVim's `<leader>uD`
e('<leader>ud', {
	win = 'lazyvim',
	lazyvim = { desc = 'Toggle Diagnostics' },
	koala = { desc = 'Toggle dim', drop = '<leader>uD' },
})
e('<leader>fr', {
	lazyvim = { desc = 'Recent', to = '<leader>fo' },
	koala = { desc = 'Find resume', drop = '<leader>sR' },
})
lv_move('<leader>fR', 'Recent (cwd)', '<leader>fO')

-- git
e('<leader>gg', {
	lazyvim = { desc = 'Lazygit', drop = '<leader>gG', optional = true },
	koala = { desc = 'diff_viewer', to = '<leader>gV' },
})
e('<leader>gs', {
	lazyvim = { desc = 'Git Status', drop = 'neogit <leader>gs' },
	koala = { desc = 'Open Neogit', to = '<leader>gn' },
})
e('<leader>gd', {
	lazyvim = { desc = 'Git Diff (hunks)', drop = 'codediff <leader>gd' },
	koala = { desc = 'Git show diff', to = '<leader>gv' },
})
e('<leader>gD', {
	lazyvim = { desc = 'Git Diff (origin)', drop = true },
	koala = { desc = 'Git dirtyfiles', drop = '<leader>gs' },
})
e('<leader>gp', {
	lazyvim = { desc = 'GitHub Pull Requests (open)', drop = 'octo <leader>gr' },
	koala = { desc = 'Git push', to = '<leader>gu' },
})
e('<leader>gP', {
	lazyvim = { desc = 'GitHub Pull Requests (all)', drop = 'octo <leader>gR' },
	koala = { desc = 'Git push (alias)', to = '<leader>gU' },
})
e('<leader>gI', {
	lazyvim = { desc = 'GitHub Issues (all)', drop = 'octo <leader>gI' },
	koala = { desc = 'Search Issues (Octo)', to = '<leader>gOI' },
})
e('<leader>gS', {
	lazyvim = { desc = 'Git Stash', drop = true },
	koala = { desc = 'Search (Octo)', to = '<leader>gOS' },
})
e('<leader>gl', {
	lazyvim = { desc = 'Git Log', drop = '<leader>gL' },
	koala = { desc = 'List Repos (Octo)', to = '<leader>gOl' },
})
-- `gi` is a single key on top of octo's `gic`/`gil`
lv_drop('<leader>gi', 'GitHub Issues (open)', 'octo <leader>gic')
-- Octo moves as a group in the lazyvim flavor
kv_move('<leader>gr', 'List PRs (Octo)', '<leader>gOr')
kv_move('<leader>gR', 'Search PRs (Octo)', '<leader>gOR')
kv_move('<leader>gic', 'Create Issue (Octo)', '<leader>gOic')
kv_move('<leader>gil', 'List Issues (Octo)', '<leader>gOil')
-- `gh` is LazyVim's hunks group (`ghs`, `ghr`, ...), codediff's file history duplicates LazyVim's `<leader>gf`
kv_drop('<leader>gh', 'Git file History', '<leader>gf')
lv_drop('<leader>gf', 'Git Current File History', 'codediff <leader>gh')

-- insert
e('<C-k>', {
	mode = 'i',
	lazyvim = { desc = 'Signature Help', drop = '<c-l>', optional = true },
	koala = { desc = 'Insert new line', drop = true },
})
-- Window navigation: KoalaVim's Navigator extends LazyVim's `<C-w>hjkl` mappings (tmux/wezterm aware), kept in both flavors
for _, nav in ipairs({ { 'h', 'Left' }, { 'j', 'Lower' }, { 'k', 'Upper' }, { 'l', 'Right' } }) do
	e('<C-' .. nav[1] .. '>', {
		win = 'koala',
		lazyvim = { desc = 'Go to ' .. nav[2] .. ' Window', drop = 'Navigator' },
		koala = { desc = 'Navigate' },
	})
end
e('<C-s>', {
	lazyvim = { desc = 'Save File', drop = 'vim default', mode = { 'n', 'i', 'x', 's' } },
	koala = { desc = 'Open Git Status', drop = '<leader>gn' },
})
for _, k in ipairs({ 'j', 'k' }) do
	local dir = k == 'j' and 'Down' or 'Up'
	e('<M-' .. k .. '>', {
		lazyvim = { desc = 'Move ' .. dir, drop = 'move.nvim / vim default', mode = { 'n', 'i', 'v' } },
		koala = {
			desc = 'Jump to ' .. (k == 'j' and 'next' or 'previous') .. ' git hunk',
			drop = k == 'j' and ']h' or '[h',
			optional = true,
		},
	})
end

-- Window resize (LazyVim) vs multi cursor / sibling swap (KoalaVim)
e('<C-Up>', {
	lazyvim = { desc = 'Increase Window Height', drop = '<C-w> hydra' },
	koala = { desc = 'add above', to = '<M-Up>' },
})
e('<C-Down>', {
	lazyvim = { desc = 'Decrease Window Height', drop = '<C-w> hydra' },
	koala = { desc = 'add below', to = '<M-Down>' },
})
e('<C-Left>', {
	lazyvim = { desc = 'Decrease Window Width', drop = '<C-w> hydra' },
	koala = { desc = 'Swap with left sibling', to = '<M-Left>' },
})
e('<C-Right>', {
	lazyvim = { desc = 'Increase Window Width', drop = '<C-w> hydra' },
	koala = { desc = 'Swap with right sibling', to = '<M-Right>' },
})

-- Hunk / class / diagnostic / breakpoint navigation
-- KoalaVim's treesitter-textobjects config disables LazyVim's class jumps (`]c` `[c` `]C` `[C`) in the koala flavor
-- itself (`move.keys`, see `plugins/treesitter.lua`), the entries document and verify it.
for _, k in ipairs({ ']', '[' }) do
	local nxt = k == ']'
	e(k .. 'c', {
		lazyvim = {
			desc = (nxt and 'Next' or 'Prev') .. ' Class Start',
			drop = nxt and ']]' or '[[',
			optional = true,
			mode = { 'n', 'x', 'o' },
		},
		koala = {
			desc = 'Jump to ' .. (nxt and 'next' or 'previous') .. ' git hunk',
			drop = nxt and ']h' or '[h',
			optional = true,
		},
	})
	e(k .. 'C', {
		lazyvim = {
			desc = (nxt and 'Next' or 'Prev') .. ' Class End',
			drop = true,
			optional = true,
			mode = { 'n', 'x', 'o' },
		},
		koala = { desc = 'Jump to ' .. (nxt and 'next' or 'previous') .. ' git dirty file', to = nxt and ']G' or '[G' },
	})
	-- Class motion (koala flavor: `]]`/`[[`, LazyVim's illuminate references win them in the lazyvim flavor)
	e(k .. k, {
		lazyvim = {
			desc = (nxt and 'Next' or 'Prev') .. ' Reference',
			drop = nxt and '<C-n>' or '<C-p>',
			optional = true,
		},
		koala = {
			desc = 'goto_' .. (nxt and 'next' or 'previous') .. '_start @class.outer',
			drop = k .. 'c',
			optional = true,
			mode = { 'n', 'x', 'o' },
		},
	})
	e(k .. 'd', {
		lazyvim = { desc = (nxt and 'Next' or 'Prev') .. ' Diagnostic', drop = k .. 'w' },
		koala = { desc = 'Goto ' .. (nxt and 'next' or 'prev') .. ' breakpoint', to = nxt and ']r' or '[r' },
	})
	e(k .. 'w', {
		lazyvim = { desc = (nxt and 'Next' or 'Prev') .. ' Warning', drop = true },
		koala = { desc = (nxt and 'Next' or 'Prev') .. ' diagnostic (warning)', drop = k .. 'd' },
	})
	e(k .. 'e', {
		lazyvim = { desc = (nxt and 'Next' or 'Prev') .. ' Error', drop = true },
		koala = { desc = (nxt and 'Next' or 'Prev') .. ' error', drop = true },
	})
	kv_drop(k .. 'g', (nxt and 'Next' or 'Prev') .. ' error', k .. 'e')
end
kv_drop('<C-n>', 'jump to Next occurrence', ']]')
kv_drop('<C-p>', 'jump to Previous occurrence', '[[')

-- Arrow keys: LazyVim moves through wrapped lines, KoalaVim scrolls
e('<Down>', {
	mode = { 'n', 'x' },
	lazyvim = { desc = 'Down', drop = true },
	koala = { desc = 'Down to scroll', drop = true },
})
e('<Up>', {
	mode = { 'n', 'x' },
	lazyvim = { desc = 'Up', drop = true },
	koala = { desc = 'Up to scroll', drop = true },
})
-- `j`/`k` are the same action in both
for _, k in ipairs({ 'j', 'k' }) do
	local dir = k == 'j' and 'Down' or 'Up'
	e(k, {
		mode = { 'n', 'x' },
		lazyvim = { desc = dir, drop = 'KoalaVim ' .. k },
		koala = { desc = 'Move ' .. dir:lower() .. ' inside wrapped line', drop = 'LazyVim ' .. k },
	})
end

-- Windows: KoalaVim's `<C-w>` resizer hydra vs LazyVim's which-key window hydra
e('<C-w>', { koala = { desc = 'window_resizer', drop = '<c-w><space>' } })
lv_drop('<C-w><space>', 'Window Hydra Mode', '<C-w> hydra')

-- LSP doc scrolling: LazyVim noice `<c-f>`/`<c-b>`, KoalaVim `<c-d>`/`<c-u>`
for _, k in ipairs({ 'f', 'b' }) do
	lv_drop(
		'<C-' .. k .. '>',
		k == 'f' and 'Scroll Forward' or 'Scroll Backward',
		'KoalaVim <c-d>/<c-u>',
		{ mode = { 'n', 'i', 's' } }
	)
end
kv_drop('<C-d>', 'Scroll down in hover', '<c-f>')
kv_drop('<C-u>', 'Scroll up in hover', '<c-b>')

-- Explorer: LazyVim's snacks explorer is disabled in both flavors (phase 3), the lazyvim flavor gets `<leader>e` on
-- nvim-tree (see `adds`). FeMaco, and golang's "if err" (buffer-local `<leader>e`), move.
e('<leader>e', {
	lazyvim = { desc = 'Explorer' },
	koala = { desc = 'Edit markdown codeblocks', to = '<leader>cE' },
})
e('<leader>e', {
	ft = 'go',
	-- go.nvim (which defines it) is disabled
	koala = { desc = 'Golang: create if err', to = '<leader>cI', optional = true },
})
e('<leader>E', { lazyvim = { desc = 'Explorer' } })

-- Terminal: koala flavor uses toggleterm (<C-t>), the lazyvim flavor snacks terminal. `ft`/`fT` are reused for todo.
lv_drop('<leader>ft', 'Terminal (Root Dir)', 'toggleterm <C-t>')
lv_drop('<leader>fT', 'Terminal (cwd)', 'toggleterm <C-t>')
lv_drop('<C-/>', 'Terminal (Root Dir)', 'toggleterm <C-t>', { mode = { 'n', 't' } })
lv_drop('<C-_>', nil, 'toggleterm <C-t>', { mode = { 'n', 't' } })

--------------------------------------------------------------------------------------------------------------------
-- B. Prefix collisions: a KoalaVim single key sits on a LazyVim group (or the other way around)
--------------------------------------------------------------------------------------------------------------------

-- KoalaVim's black-hole change/delete live on `<leader>c`/`<leader>d`: LazyVim's code/debug groups move (see `prefixes`).
-- In the lazyvim flavor they become the `<leader>C`/`<leader>D` operators, the `"_C`/`"_D` line variants are dropped
-- (use `<leader>C$`/`<leader>D$`).
kv_move('<leader>c', 'change without yanking', '<leader>C')
kv_drop('<leader>C', 'change rest of line without yanking', '<leader>C$')
kv_move('<leader>d', 'delete without yanking', '<leader>D')
kv_drop('<leader>D', 'delete rest of line without yanking', '<leader>D$')
-- Build & deploy lives on `<leader>b` (LazyVim's buffer group)
kv_move('<leader>b', 'Build & deploy', '<leader>rb')
kv_move('<leader>B', 'Reset deploy', '<leader>rB')
-- Spell hydra lives on `<leader>s` (LazyVim's search group). LazyVim owns `<leader>uz` (zen), so the hydra goes to `uZ`.
kv_move('<leader>s', 'spell fixer', '<leader>uZ')
-- `<leader><Tab>` (last buffer) is LazyVim's tabs group, `<leader>bb` does the same
kv_drop('<leader><Tab>', 'Go to last active tab', '<leader>bb')
-- LazyVim's single `fc` (config file) and `fn` (new file) sit under KoalaVim's `fc*`/`fn*` families
lv_move('<leader>fc', 'Find Config File', '<leader>fv')
lv_drop('<leader>fn', 'New File', true)
kv_move('<leader>fn', nil, '<leader>fN', { mode = 'x' })

--------------------------------------------------------------------------------------------------------------------
-- C. LazyVim overrides of vim defaults (removed in the koala flavor)
--------------------------------------------------------------------------------------------------------------------

lv_drop('H', 'Prev Buffer', 'vim default')
lv_drop('L', 'Next Buffer', 'vim default')
-- KoalaVim's treesitter block jumps sit on LazyVim's buffer keys, they move to `]o`/`[o`/`]O`/`[O` in the lazyvim flavor
-- (`o` is the block object of mini.ai)
for _, b in ipairs({
	{ ']b', 'Next Buffer', 'goto_next_start', ']o' },
	{ '[b', 'Prev Buffer', 'goto_previous_start', '[o' },
	{ ']B', 'Move buffer next', 'goto_next_end', ']O' },
	{ '[B', 'Move buffer prev', 'goto_previous_end', '[O' },
}) do
	e(b[1], {
		lazyvim = { desc = b[2], drop = 'vim default' },
		koala = { desc = b[3] .. ' @block.outer', to = b[4], mode = { 'n', 'x', 'o' } },
	})
end
lv_drop('<Esc>', 'Escape and Clear hlsearch', 'vim default', { mode = { 'i', 'n', 's' } })
for _, k in ipairs({ ',', '.', ';' }) do
	lv_drop(k, nil, 'vim default', { mode = 'i' })
end
lv_drop('<', nil, 'vim default', { mode = 'x' })
lv_drop('>', nil, 'vim default', { mode = 'x' })
lv_drop('gco', 'Add Comment Below', 'vim default')
lv_drop('gcO', 'Add Comment Above', 'vim default')
lv_drop('<leader>-', 'Split Window Below', '<M-o>')
lv_drop('<leader>|', 'Split Window Right', '<M-e>')
-- `n`/`N`: KoalaVim recenters (`nzz`), LazyVim searches in the same direction and opens folds
e('n', {
	lazyvim = { desc = 'Next Search Result', drop = 'vim default / KoalaVim n', mode = { 'n', 'x', 'o' } },
	koala = { desc = 'Auto recenter after n', drop = 'LazyVim n' },
})
e('N', {
	lazyvim = { desc = 'Prev Search Result', drop = 'vim default / KoalaVim N', mode = { 'n', 'x', 'o' } },
	koala = { desc = 'Auto recenter after N', drop = 'LazyVim N' },
})

--------------------------------------------------------------------------------------------------------------------
-- D. Same intent, different key (the other side's key is removed)
--------------------------------------------------------------------------------------------------------------------

-- format
lv_drop('<leader>cf', 'Format', '<leader>F', { mode = { 'n', 'x' } })
kv_drop('<leader>F', 'Format', '<leader>cf', { mode = { 'n', 'x' } })
-- rename / code action / line diagnostics (lspsaga is gone, KoalaVim's `<F2>`/`<F4>`/`<leader>L` are native)
lv_drop('<leader>cr', 'Rename', '<F2>', OPT)
lv_drop('<leader>ca', 'Code Action', '<F4>', { mode = { 'n', 'x' }, optional = true })
lv_drop('<leader>cd', 'Line Diagnostics', '<leader>L')
kv_drop('<F2>', 'Rename symbols', '<leader>cr')
kv_drop('<F4>', 'Code action', '<leader>ca')
-- inlay hints
lv_drop('<leader>uh', 'Toggle Inlay Hints', '<leader>T')
kv_drop('<leader>T', 'Toggle inlay-hints', '<leader>uh')
-- trouble: buffer diagnostics (LazyVim's `<leader>xx` all diagnostics stays)
lv_drop('<leader>xX', 'Buffer Diagnostics (Trouble)', '<leader>t')
kv_drop('<leader>t', 'Buffer Diagnostics (Trouble)', '<leader>xX')
-- markdown preview
lv_drop('<leader>cp', 'Markdown Preview', '<leader>up', OPT)
kv_drop('<leader>up', 'Markdown Preview', '<leader>cp', OPT)
-- implementation / type definition / definition / references / declaration / hover (LSP keys vs KoalaVim's pickers)
e('gI', { lazyvim = { desc = 'Goto Implementation', drop = 'gi', optional = true } })
e('gi', { koala = { desc = 'Go to Implementation', drop = 'gI' } })
e('gy', { lazyvim = { desc = 'Goto T[y]pe Definition', drop = 'gt', optional = true } })
e('gt', { koala = { desc = 'Go to Type', drop = 'gy' } })
e('gd', {
	lazyvim = { desc = 'Goto Definition', drop = 'KoalaVim gd', optional = true },
	koala = { desc = 'Go to Definition', drop = 'LazyVim gd' },
})
e('gr', {
	lazyvim = { desc = 'References', drop = 'KoalaVim gr', optional = true },
	koala = { desc = 'Go to References', drop = 'LazyVim gr' },
})
e('gD', {
	lazyvim = { desc = 'Goto Declaration', drop = 'KoalaVim gD', optional = true },
	koala = { desc = 'Go to Declaration', drop = 'LazyVim gD' },
})
e('K', {
	lazyvim = { desc = 'Hover', drop = 'KoalaVim K', optional = true },
	koala = { desc = 'Trigger hover', drop = 'LazyVim K' },
})
-- vtsls' `gD` (go to source definition) duplicates the declaration key
e('gD', {
	ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
	lazyvim = { desc = 'Goto Source Definition', drop = 'KoalaVim gD', optional = true },
})
-- goto-function hydra (`gj gk gJ gK`) vs LazyVim's signature help; `[F` does the same without the hydra
e('gK', {
	lazyvim = { desc = 'Signature Help', drop = 'KoalaVim <c-l> / vim default', optional = true },
	koala = { desc = 'Go up to an end of a function', drop = '[F', mode = { 'n', 'x' } },
})
-- Floating terminal / file history: see section A. Hunks (gitsigns `on_attach`): LazyVim `]h [h` `<leader>gh*`
lv_drop(']h', 'Next Hunk', ']c', OPT)
lv_drop('[h', 'Prev Hunk', '[c', OPT)
for _, h in ipairs({
	{ 's', 'Stage Hunk', { 'n', 'v' } },
	{ 'r', 'Reset Hunk', { 'n', 'v' } },
	{ 'S', 'Stage Buffer', 'n' },
	{ 'u', 'Undo Stage', 'n' },
	{ 'R', 'Reset Buffer', 'n' },
	{ 'p', 'Preview Hunk', 'n' },
	{ 'b', 'Blame Line', 'n' },
}) do
	kv_drop('<leader>h' .. h[1], h[2], '<leader>gh' .. h[1], { mode = h[3], optional = true })
end
-- The hunk textobject `ih` is defined by both on_attach functions
kv_drop('ih', nil, 'LazyVim ih', { mode = { 'o', 'x' } })
-- dap.core's keys that repeat KoalaVim's F-keys / `<leader>rc` / `<leader>rp` / `<leader>k`
for _, d in ipairs({
	{ '<leader>db', 'Toggle Breakpoint', '<F9>' },
	{ '<leader>dc', 'Run/Continue', '<F5>' },
	{ '<leader>di', 'Step Into', '<F11>' },
	{ '<leader>dO', 'Step Over', '<F10>' },
	{ '<leader>do', 'Step Out', '<F12>' },
	{ '<leader>dC', 'Run to Cursor', '<leader>rc' },
	{ '<leader>de', 'Eval', '<leader>k', { mode = { 'n', 'x' } } },
}) do
	lv_drop(d[1], d[2], d[3], d[4])
end
lv_drop('<leader>dr', 'Toggle REPL', '<leader>rp')
-- `<leader>dt` would move to `<leader>rt`, which is KoalaVim's rust testables
lv_drop('<leader>dt', 'Terminate', '<F6>')
-- `ss`/`sS` (LSP symbols) duplicate KoalaVim's `gs`/`fs`
lv_drop('<leader>ss', 'LSP Symbols', 'gs', OPT)
lv_drop('<leader>sS', 'LSP Workspace Symbols', '<leader>fs', OPT)

--------------------------------------------------------------------------------------------------------------------
-- E. Koala flavor: LazyVim's search group `<leader>s*` merges into `<leader>f*` (D47)
--------------------------------------------------------------------------------------------------------------------

-- { LazyVim lhs, merged lhs, LazyVim desc, mode }
for _, m in ipairs({
	{ 'sb', 'fl', 'Buffer Lines' },
	{ 'sB', 'fG', 'Grep Open Buffers' },
	{ 'sp', 'fP', 'Search for Plugin Spec' },
	{ 's"', 'f"', 'Registers' },
	{ 's/', 'f/', 'Search History' },
	{ 'sa', 'fa', 'Autocmds' },
	{ 'sc', 'f:', 'Command History' },
	{ 'sC', 'fC', 'Commands' },
	{ 'sd', 'fd', 'Diagnostics' },
	{ 'sD', 'fD', 'Buffer Diagnostics' },
	{ 'sh', 'fh', 'Help Pages' },
	{ 'sH', 'fH', 'Highlights' },
	{ 'sj', 'fj', 'Jumps' },
	{ 'sk', 'fk', 'Keymaps' },
	{ 'sl', 'fQ', 'Location List' },
	{ 'sq', 'fq', 'Quickfix List' },
	{ 'sM', 'fM', 'Man Pages' },
	{ 'sm', "f'", 'Marks' },
	{ 'su', 'fu', 'Undotree' },
	{ 'st', 'ft', 'Todo' },
	{ 'sT', 'fT', 'Todo/Fix/Fixme' },
	{ 'snl', 'fNl', 'Noice Last Message' },
	{ 'sna', 'fNa', 'Noice All' },
	{ 'snt', 'fNt', 'Noice Picker' },
}) do
	lv_move('<leader>' .. m[1], m[3], '<leader>' .. m[2])
end
-- Dropped, KoalaVim has the same action
for _, d in ipairs({
	{ 'sg', 'Grep (Root Dir)', '<leader>fw', { 'n' } },
	{ 'sG', 'Grep (cwd)', '<leader>fcdd', { 'n' } },
	{ 'sw', 'Visual selection or word (Root Dir)', '<leader>fcw', { 'n', 'x' } },
	{ 'sW', 'Visual selection or word (cwd)', '<leader>fcW', { 'n', 'x' } },
	{ 'sR', 'Resume', '<leader>fr', { 'n' } },
	{ 'si', 'Icons', '<leader>fi', { 'n' } },
	{ 'snh', 'Noice History', '<leader>N', { 'n' } },
	{ 'snd', 'Dismiss All', '<leader>un', { 'n' } },
	{ 'sn', '+noice', 'group label', { 'n' } },
	{ 'sr', 'Search and Replace', '<leader>fnr', { 'n', 'x' } },
}) do
	lv_drop('<leader>' .. d[1], d[2], d[3], { mode = d[4], optional = true })
end
-- LazyVim's own `<leader>f*` keys that collide with KoalaVim's
e('<leader>fb', {
	lazyvim = { desc = 'Buffers', drop = 'KoalaVim <leader>fb' },
	koala = { desc = 'Browse open buffers', drop = 'LazyVim <leader>fb' },
})
e('<leader>ff', {
	lazyvim = { desc = 'Find Files', drop = 'KoalaVim <leader>ff' },
	koala = { desc = 'Find file', drop = 'LazyVim <leader>ff' },
})
lv_drop('<leader>fe', 'Explorer', 'nvim-tree <M-m>', OPT)
lv_drop('<leader>fE', 'Explorer', 'nvim-tree <M-M>', OPT)
-- Buffers `<leader>b*` -> `<leader>q*` (prefix rule), these are duplicates of KoalaVim's `<leader><Tab>`/`qq`/`qa`
lv_drop('<leader>bb', 'Switch to Other Buffer', '<leader><Tab>')
lv_drop('<leader>bd', 'Delete Buffer', '<leader>qq')
lv_drop('<leader>bo', 'Delete Other Buffers', '<leader>qa')
-- Code / debug keys with an explicit target (the rest is moved by `prefixes`)
lv_move('<leader>dPt', 'Debug Method', '<leader>rT', { ft = 'python', optional = true })
lv_move('<leader>dPc', 'Debug Class', '<leader>rC', { ft = 'python', optional = true })
lv_move('<leader>dr', 'Rust Debuggables', '<leader>rd', { ft = 'rust', optional = true })

---@type KoalaVim.Keymaps.PrefixRule[]
local prefixes = {
	-- koala flavor: LazyVim's groups move out of KoalaVim's way. The longest matching `from` wins and explicit entries
	-- (above) take precedence over prefix rules.
	{ side = 'lazyvim', from = '<leader>dp', to = '<leader>uP' }, -- profiler
	{ side = 'lazyvim', from = '<leader>d', to = '<leader>r' }, -- debug
	{ side = 'lazyvim', from = '<leader>c', to = '<leader>v' }, -- code (incl. language extras and LSP keys)
	{ side = 'lazyvim', from = '<leader>b', to = '<leader>q' }, -- buffers
	{ side = 'lazyvim', from = '<leader><tab>', drop = 'KoalaVim tabpage keys' },
	{ side = 'lazyvim', from = '<leader>gh', drop = 'KoalaVim <leader>h*' }, -- gitsigns hunks
	-- lazyvim flavor: KoalaVim's families that sit under a LazyVim single key
	{ side = 'koala', from = '<leader>fc', to = '<leader>fC' }, -- find current word/dir (LazyVim's `fc`: config file)
	{ side = 'koala', from = '<leader>fn', to = '<leader>fN' }, -- spectre (LazyVim's `fn`: new file)
}

--- Keys LazyVim lost (koala flavor) / KoalaVim features that need a LazyVim-layout key (lazyvim flavor)
---@type table<'koala'|'lazyvim', KoalaVim.Keymaps.Add[]>
local adds = {
	koala = {
		{ 'n', '<leader>zz', '<cmd>Lazy<cr>', desc = 'Lazy' },
		{
			'n',
			'<leader>zl',
			function()
				require('lazyvim.util').news.changelog()
			end,
			desc = 'LazyVim Changelog',
		},
		{ 'n', '<leader>zx', '<cmd>LazyExtras<cr>', desc = 'LazyVim Extras' },
	},
	lazyvim = {
		-- LazyVim's snacks explorer is disabled, the explorer keys open nvim-tree (`<M-m>`, `<M-M>` stay)
		{
			'n',
			'<leader>e',
			function()
				require('nvim-tree.api').tree.toggle()
			end,
			desc = 'Explorer (nvim-tree)',
		},
		{
			'n',
			'<leader>E',
			function()
				require('nvim-tree.api').tree.open({ find_file = true })
			end,
			desc = 'Explorer (nvim-tree, locate file)',
		},
	},
}

--- Intentional ambiguous leader prefixes, `check()` doesn't report them: `{ mode, lhs }` of the SHORTER key.
--- E.g. modal hydra bodies that are also a prefix of other keys.
---@type { [1]: string, [2]: string }[]
local allow_prefix = {}

return {
	entries = entries,
	prefixes = prefixes,
	adds = adds,
	allow_prefix = allow_prefix,
}
