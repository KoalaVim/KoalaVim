local M = {}

table.insert(M, {
	-- ChatGPT from nvim
	'jackMort/ChatGPT.nvim',
	cmd = { 'ChatGPT', 'ChatGPTActAs', 'ChatGPTRunCustomCodeAction', 'ChatGPTEditWithInstructions' },
	config = function()
		require('chatgpt').setup()
	end,
	dependencies = {
		'MunifTanjim/nui.nvim',
		'nvim-lua/plenary.nvim',
		'nvim-telescope/telescope.nvim',
	},
})

table.insert(M, {
	-- Quick ChatGPT from nvim, <C-a> in insert mode or :AI in selection
	'aduros/ai.vim',
	cmd = 'AI',
	init = function()
		vim.g.ai_no_mappings = true
	end,
})

--- Opens a split with a temporary buffer for editing a prompt.
--- On closing the buffer, sends its content to sidekick CLI.
local function edit_prompt()
	-- FIXME: get prompt
	local bufid = vim.api.nvim_create_buf(false, true)

	-- Enter insert mode when focusing the buffer
	vim.api.nvim_create_autocmd('BufEnter', {
		buffer = bufid,
		once = true,
		callback = vim.schedule_wrap(function()
			vim.cmd('startinsert')
		end),
	})

	-- Send content to sidekick CLI when closing the buffer
	vim.api.nvim_create_autocmd('BufWinLeave', {
		buffer = bufid,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(bufid, 0, -1, false)
			local content = table.concat(lines, '\n')
			if content ~= '' then
				require('sidekick.cli').send({ msg = content })
			end
		end,
	})

	vim.cmd('split')
	local win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(0, bufid)
	vim.api.nvim_win_set_height(0, math.ceil(vim.o.lines * 0.3))
	vim.bo[bufid].filetype = 'sidekick_koala_prompt'

	---@param items sidekick.context.Loc[]
	paste_to_buffer_cb = function(items)
		local Loc = require('sidekick.cli.context.location')
		local ret = { { ' ' } } ---@type sidekick.Text
		for _, item in ipairs(items) do
			local file = Loc.get(item, { kind = 'file' })[1]
			if file then
				vim.list_extend(ret, file)
				ret[#ret + 1] = { ' ' }
			end
		end
		vim.schedule(function()
			-- ret = { { " " }, { "@", "SidekickLocDelim" }, { "docs/loadbalancing-architecture.md", "SidekickLocFile" }, { " " } }
			local text = table.concat(
				vim.tbl_map(function(c)
					-- c[2] is highlight (if exist)
					return c[1]
				end, ret),
				''
			)
			vim.api.nvim_set_current_win(win_id)
			vim.api.nvim_put({ text }, '', true, true)
		end)
	end

	local picker = require('sidekick.cli.picker').get()
	vim.keymap.set('n', 'q', '<cmd>q<CR>', { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-f>', function()
		picker.open('files', paste_to_buffer_cb, {})
	end, { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-b>', function()
		picker.open('buffers', paste_to_buffer_cb, {})
	end, { buffer = bufid })
end

local function nav_to_prompt(search_char)
	local f = function()
		vim.fn.setreg('/', ' ┌─')
		vim.cmd('normal! ' .. search_char)
	end

	if vim.fn.mode() == 't' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true), 'n', false)
		f = vim.schedule_wrap(f)
	end
	f()
end

table.insert(M, {
	'folke/sidekick.nvim',
	opts = {
		cli = {
			---@class sidekick.win.Opts
			win = {
				split = {
					width = 0,
					height = 0,
				},
				keys = {
					-- Using Navigator.nvim to navigate
					nav_left = {
						'<c-h>',
						'<cmd>NavigatorLeft<cr>',
						expr = false,
						desc = 'navigate to the left window',
					},
					nav_down = {
						'<c-j>',
						'<cmd>NavigatorDown<cr>',
						expr = false,
						desc = 'navigate to the below window',
					},
					nav_up = {
						'<c-k>',
						'<cmd>NavigatorUp<cr>',
						expr = false,
						desc = 'navigate to the above window',
					},
					nav_right = {
						'<c-l>',
						'<cmd>NavigatorRight<cr>',
						expr = false,
						desc = 'navigate to the right window',
					},
				},
			},
		},
	},
	keys = {
		{
			'<C-g>',
			'<cmd>DiffviewOpen<cr>',
			ft = 'sidekick_terminal',
			desc = 'Open Diff',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'<C-.>',
			'<S-tab>',
			ft = 'sidekick_terminal',
			desc = 'Switch cursor modes',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'<C-e>',
			function()
				edit_prompt()
			end,
			ft = 'sidekick_terminal',
			desc = 'edit prompt in neovim buffer',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			']p',
			function()
				nav_to_prompt('n')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'[p',
			function()
				nav_to_prompt('N')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'gj',
			function()
				nav_to_prompt('n')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = 'n',
		},
		{
			-- FIXME: apply only in cursor
			'gk',
			function()
				nav_to_prompt('N')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = 'n',
		},
		{
			'<leader>uN',
			function()
				require('sidekick.nes').toggle()
			end,
			desc = 'Toggle sidekick NES',
		},
		-- nes is also useful in normal mode
		-- FIXME: enable 'nes'
		-- { '<tab>', LazyVim.cmp.map({ 'ai_nes' }, '<tab>'), mode = { 'n' }, expr = true },
		{ '<leader>a', '', desc = '+ai', mode = { 'n', 'v' } },
		{
			'<c-.>',
			function()
				require('sidekick.cli').toggle()
			end,
			desc = 'Sidekick Toggle',
			mode = { 'n', 't', 'i', 'x' },
		},
		{
			'<leader>ai',
			function()
				-- FIXME: default agent from koalaconfig
				require('sidekick.cli').show({ name = 'cursor' })
			end,
			desc = 'Open/Focus AI',
		},
		{
			'<leader>aa',
			function()
				require('sidekick.cli').toggle()
			end,
			desc = 'Sidekick Toggle CLI',
		},
		{
			'<leader>as',
			function()
				require('sidekick.cli').select()
			end,
			-- Or to select only installed tools:
			-- require("sidekick.cli").select({ filter = { installed = true } })
			desc = 'Select CLI',
		},
		{
			'<leader>ad',
			function()
				require('sidekick.cli').close()
			end,
			desc = 'Detach a CLI Session',
		},
		{
			'<leader>at',
			function()
				require('sidekick.cli').send({ msg = '{this}' })
			end,
			mode = { 'x', 'n' },
			desc = 'Send This',
		},
		{
			'<leader>af',
			function()
				require('sidekick.cli').send({ msg = '{file}' })
			end,
			desc = 'Send File',
		},
		{
			'<leader>av',
			function()
				require('sidekick.cli').send({ msg = '{selection}' })
			end,
			mode = { 'x' },
			desc = 'Send Visual Selection',
		},
		{
			'<leader>ap',
			function()
				require('sidekick.cli').prompt()
			end,
			mode = { 'n', 'x' },
			desc = 'Sidekick Select Prompt',
		},
	},
})

return M
