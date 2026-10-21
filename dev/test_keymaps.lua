-- Headless keymap invariant test (`make test-keymaps`, driven by dev/test_keymaps.sh).
--
-- Creates a temporary git repo with sample files, opens each one, waits (bounded) for the LSP client and gitsigns to
-- attach and runs `require('KoalaVim.keymaps').check()` on the buffer, so the buffer-local keys (LSP, gitsigns,
-- rustaceanvim, ...) are covered too. Fails if any violation is found.
--
-- Environment (set by the driver):
--   KM_TEST_DIR      empty directory, the repo is created inside (the driver removes it)
--   KM_TEST_OUT      the report is written here, last line is `RESULT: PASS|FAIL`
--   KM_TEST_FLAVOR   the flavor the run must have (`koala`|`lazyvim`), asserted
--   KM_TEST_LENIENT  `1`: a server that is installed but didn't attach is a warning (default: failure)
--
-- Servers that are not installed are skipped (reported, not a failure).

local DIR = assert(vim.env.KM_TEST_DIR, 'KM_TEST_DIR is not set')
local OUT = assert(vim.env.KM_TEST_OUT, 'KM_TEST_OUT is not set')
local EXPECTED_FLAVOR = vim.env.KM_TEST_FLAVOR
local LENIENT = vim.env.KM_TEST_LENIENT == '1'

local STARTUP_TIMEOUT = 60000 -- VeryLazy
local LSP_TIMEOUT = 45000 -- per file
local GITSIGNS_TIMEOUT = 15000 -- per file
local SETTLE = 1500 -- after the attach, late `on_attach` keys
local WATCHDOG = 600000 -- whole test

---@class km.Case
---@field file string          path inside the repo
---@field ft string
---@field bins string[]        the language server executables (any of them), none installed: no LSP expected
---@field content string

---@type km.Case[]
local cases = {
	{ file = 'sample.lua', ft = 'lua', bins = { 'lua-language-server' }, content = 'local x = 1\nprint(x)\n' },
	{
		file = 'go/main.go',
		ft = 'go',
		bins = { 'gopls' },
		content = 'package main\n\nfunc main() {\n\tprintln("hi")\n}\n',
	},
	{
		file = 'rust/src/main.rs',
		ft = 'rust',
		bins = { 'rust-analyzer' },
		content = 'fn main() {\n    println!("hi");\n}\n',
	},
	{ file = 'README.md', ft = 'markdown', bins = { 'marksman' }, content = '# Title\n\ntext\n' },
	{
		file = 'c/main.c',
		ft = 'c',
		bins = { 'clangd' },
		content = '#include <stdio.h>\n\nint main(void)\n{\n\treturn 0;\n}\n',
	},
}

-- Files besides the cases (project markers)
local extra_files = {
	['go/go.mod'] = 'module km.fixture\n\ngo 1.21\n',
	['rust/Cargo.toml'] = '[package]\nname = "km_fixture"\nversion = "0.1.0"\nedition = "2021"\n',
	['c/compile_flags.txt'] = '-Wall\n',
}

--------------------------------------------------------------------------------------------------------------------
-- Report
--------------------------------------------------------------------------------------------------------------------

local report = {}
local failures = 0
local finished = false

local function log(s)
	report[#report + 1] = s
end

local function fail(s)
	failures = failures + 1
	log('FAIL: ' .. s)
end

local function finish()
	if finished then
		return
	end
	finished = true
	log(('RESULT: %s'):format(failures == 0 and 'PASS' or 'FAIL'))
	local f = io.open(OUT, 'w')
	if f then
		f:write(table.concat(report, '\n') .. '\n')
		f:close()
	end
	vim.cmd('qa!')
end

vim.defer_fn(function()
	fail(('watchdog: the test did not finish in %ds'):format(WATCHDOG / 1000))
	finish()
end, WATCHDOG)

--------------------------------------------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------------------------------------------

---@param bin string
---@return boolean
local function installed(bin)
	return vim.fn.executable(bin) == 1 or vim.fn.executable(vim.fn.stdpath('data') .. '/mason/bin/' .. bin) == 1
end

--- Yields the running coroutine until `cond()` is truthy or `timeout` ms passed, returns `cond()`
---@param cond fun(): any
---@param timeout integer
---@return any
local function await(cond, timeout)
	local co = assert(coroutine.running())
	local t0 = vim.uv.hrtime()
	local timer = assert(vim.uv.new_timer())
	timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			local ok, res = pcall(cond)
			if (ok and res) or not ok or (vim.uv.hrtime() - t0) / 1e6 > timeout then
				timer:stop()
				timer:close()
				coroutine.resume(co, ok and res or nil)
			end
		end)
	)
	return coroutine.yield()
end

---@param ms integer
local function sleep(ms)
	local co = assert(coroutine.running())
	vim.defer_fn(function()
		coroutine.resume(co)
	end, ms)
	coroutine.yield()
end

--- The startup AI tool selection (snacks picker) and any other picker would swallow the keys
local function close_pickers()
	local ok, snacks = pcall(function()
		return _G.Snacks or require('snacks')
	end)
	if ok and snacks and snacks.picker and snacks.picker.get then
		for _, picker in ipairs(snacks.picker.get()) do
			pcall(function()
				picker:close()
			end)
		end
	end
end

local function sh(cmd, cwd)
	local res = vim.system(cmd, {
		cwd = cwd,
		text = true,
		-- the developer's git config (hooks, templates, signing) must not leak in
		env = { GIT_CONFIG_GLOBAL = '/dev/null', GIT_CONFIG_SYSTEM = '/dev/null' },
	}):wait()
	assert(res.code == 0, ('`%s` failed: %s'):format(table.concat(cmd, ' '), res.stderr or ''))
end

---@param root string
local function create_repo(root)
	local function write(rel, content)
		local path = root .. '/' .. rel
		vim.fn.mkdir(vim.fs.dirname(path), 'p')
		vim.fn.writefile(vim.split(content, '\n', { plain = true }), path)
	end
	vim.fn.mkdir(root, 'p')
	for _, case in ipairs(cases) do
		write(case.file, case.content:gsub('\n$', ''))
	end
	for rel, content in pairs(extra_files) do
		write(rel, content:gsub('\n$', ''))
	end
	sh({ 'git', 'init', '-q' }, root)
	sh({ 'git', 'add', '-A' }, root)
	sh({
		'git',
		'-c',
		'user.name=km-test',
		'-c',
		'user.email=km-test@example.com',
		'-c',
		'commit.gpgsign=false',
		'commit',
		'-q',
		'-m',
		'fixture',
	}, root)
	-- a working tree change, so gitsigns has a hunk
	for _, case in ipairs(cases) do
		local f = assert(io.open(root .. '/' .. case.file, 'a'))
		f:write('\n')
		f:close()
	end
end

--------------------------------------------------------------------------------------------------------------------
-- Test
--------------------------------------------------------------------------------------------------------------------

local function run()
	local flavor = require('KoalaVim.flavor').get()
	log(('flavor: %s'):format(flavor))
	if EXPECTED_FLAVOR and EXPECTED_FLAVOR ~= flavor then
		fail(('expected the `%s` flavor, got `%s` (is the --cfg ignored?)'):format(EXPECTED_FLAVOR, flavor))
		return finish()
	end

	local started = await(function()
		return vim.g.km_test_very_lazy
	end, STARTUP_TIMEOUT)
	if not started then
		fail(('`User VeryLazy` did not fire in %ds'):format(STARTUP_TIMEOUT / 1000))
		return finish()
	end
	await(function()
		return false
	end, 1500)
	close_pickers()

	local root = vim.uv.fs_realpath(DIR) .. '/repo'
	create_repo(root)
	vim.cmd.cd(vim.fn.fnameescape(root))
	vim.o.swapfile = false

	-- violation -> files it was seen in (the global keymaps are reported on every buffer)
	local violations, order = {}, {}
	local summary = {}

	for _, case in ipairs(cases) do
		close_pickers()
		local path = root .. '/' .. case.file
		vim.cmd.edit(vim.fn.fnameescape(path))
		local buf = vim.api.nvim_get_current_buf()
		local label = ('%s (%s)'):format(case.file, case.ft)

		if vim.bo[buf].filetype ~= case.ft then
			fail(('%s: filetype is `%s`'):format(label, vim.bo[buf].filetype))
		end

		local have_bin
		for _, bin in ipairs(case.bins) do
			if installed(bin) then
				have_bin = bin
				break
			end
		end

		local gitsigns = await(function()
			return vim.b[buf].gitsigns_status_dict ~= nil
		end, GITSIGNS_TIMEOUT)
		if not gitsigns then
			fail(('%s: gitsigns did not attach in %ds'):format(label, GITSIGNS_TIMEOUT / 1000))
		end

		local attached
		if have_bin then
			attached = await(function()
				return #vim.lsp.get_clients({ bufnr = buf }) > 0
			end, LSP_TIMEOUT)
			if not attached then
				local msg = ('%s: `%s` is installed but no LSP client attached in %ds'):format(
					label,
					have_bin,
					LSP_TIMEOUT / 1000
				)
				if LENIENT then
					log('WARN: ' .. msg)
				else
					fail(msg)
				end
			end
		end
		sleep(SETTLE)
		close_pickers()

		local clients = vim.tbl_map(function(c)
			return c.name
		end, vim.lsp.get_clients({ bufnr = buf }))
		table.sort(clients)

		local lsp_note
		if #clients > 0 then
			lsp_note = table.concat(clients, ',')
		elseif have_bin then
			lsp_note = 'none (installed: ' .. have_bin .. ')'
		else
			lsp_note = 'skipped (not installed: ' .. table.concat(case.bins, '/') .. ')'
		end

		local ok, res = pcall(function()
			return require('KoalaVim.keymaps').check({ bufnrs = { buf } })
		end)
		if not ok then
			fail(('%s: check() errored: %s'):format(label, res))
			res = {}
		end

		summary[#summary + 1] = ('  %-24s lsp=%-34s gitsigns=%-5s violations=%d'):format(
			label,
			lsp_note,
			tostring(gitsigns and true or false),
			#res
		)
		for _, v in ipairs(res) do
			local id = ('[%s] %s'):format(v.kind, v.msg)
			if not violations[id] then
				violations[id] = {}
				order[#order + 1] = id
			end
			local where = v.buffer and case.file or '(global)'
			if not vim.tbl_contains(violations[id], where) then
				table.insert(violations[id], where)
			end
		end
	end

	log('buffers:')
	vim.list_extend(report, summary)

	if #order > 0 then
		log(('violations (%d):'):format(#order))
		for _, id in ipairs(order) do
			log(('  %s  <- %s'):format(id, table.concat(violations[id], ', ')))
		end
		failures = failures + #order
	end
	finish()
end

-- `UIEnter` is not fired by a headless nvim, lazy.nvim loads `VeryLazy` plugins on it
vim.api.nvim_create_autocmd('User', {
	pattern = 'VeryLazy',
	once = true,
	callback = function()
		vim.g.km_test_very_lazy = true
	end,
})

local function start()
	vim.api.nvim_exec_autocmds('UIEnter', {})
	local co = coroutine.create(function()
		local ok, err = xpcall(run, debug.traceback)
		if not ok then
			fail('test crashed: ' .. tostring(err))
			finish()
		end
	end)
	coroutine.resume(co)
end

if vim.v.vim_did_enter == 1 then
	vim.schedule(start)
else
	vim.api.nvim_create_autocmd('VimEnter', {
		once = true,
		callback = function()
			vim.schedule(start)
		end,
	})
end
