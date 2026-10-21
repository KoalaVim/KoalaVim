local M = {}

local usercmd = require('KoalaVim.utils.cmd')
local kkeys = require('KoalaVim.utils.map').kkeys

-- Prepend `config` to the dap configurations of `ft`, replacing a configuration with the same name
-- (LazyVim's lang extras and mason-nvim-dap register theirs, keep them)
local function add_config(dap, ft, config)
	local configs = vim.tbl_filter(function(c)
		return c.name ~= config.name
	end, dap.configurations[ft] or {})
	table.insert(configs, 1, config)
	dap.configurations[ft] = configs
end

-- KoalaVim's adapters, configurations and signs.
-- Runs as the `opts` of nvim-dap: after the lang extras registered their adapters (nvim-dap-python, dap-go),
-- and before the `dap.core` extra's config (mason-nvim-dap, defines the signs from `LazyVim.config.icons.dap`)
local function setup_dap()
	local dap = require('dap')
	dap.defaults.fallback.stepping_granularity = 'line'

	--- Signs ---
	-- Sign priority = 11
	-- Override LazyVim's sign icons, the `dap.core` extra defines the signs from them
	local icons = LazyVim.config.icons.dap
	icons.Breakpoint = { '', 'DapBreakpoint' }
	icons.BreakpointCondition = { '', 'DapCondBreakpoint' }
	icons.BreakpointRejected = { '', 'DapBreakpoint' }
	icons.LogPoint = { '', 'DiagnosticWarn' }
	icons.Stopped = { '', 'DiagnosticInfo', 'CursorLine' }

	--- Setup Adapaters ---

	-- C/C++/Rust
	local launch_file = {
		name = 'Launch file',
		type = 'codelldb',
		request = 'launch',
		program = require('KoalaVim.utils.debug').choose_file,
		cwd = vim.fn.getcwd(),
		stopOnEntry = false,
	}
	add_config(dap, 'cpp', launch_file)
	add_config(dap, 'rust', launch_file)

	dap.adapters.codelldb = {
		type = 'server',
		port = '${port}',
		executable = {
			command = 'codelldb',
			args = { '--port', '${port}' },
		},
	}

	-- C (remote gdb)
	add_config(dap, 'c', {
		name = 'Attach to gdbserver :1234',
		type = 'cppdbg',
		request = 'launch',
		MIMode = 'gdb',
		miDebuggerServerAddress = 'localhost:1234',
		miDebuggerPath = 'gdb',
		program = require('KoalaVim.utils.debug').choose_file,
		cwd = vim.fn.getcwd(),
		stopOnEntry = false,
	})

	-- From mason
	dap.adapters.cppdbg = {
		id = 'cppdbg',
		type = 'executable',
		command = 'OpenDebugAD7',
	}

	-- Golang (remote delve), dap-go from the go extra provides the local adapter/configurations
	add_config(dap, 'go', {
		name = 'Launch Remote',
		type = 'go_remote',
		request = 'attach',
		mode = 'remote',
		remotePath = '~/go/volumez',
		port = 2345,
		apiVersion = 2,
		cwd = '${workspaceFolder}',
		trace = 'verbose',
	})

	dap.adapters.go_remote = {
		type = 'server',
		host = 'rhel8-6.local',
		port = 2345,
	}

	-- Python: adapter and configurations (with venv detection) come from nvim-dap-python (python extra)

	usercmd.create('ClearBreakpoints', 'Debug: clear all breakpoints', function()
		require('dap').clear_breakpoints()
	end, {})

	require('KoalaVim.utils.debug').init()
end

-- Debug Adapter Protocol client — debug code from Neovim (cpp/rust/go/python), `dap.core` extra provides the base
table.insert(M, {
	'mfussenegger/nvim-dap',
	dependencies = {
		'rcarriga/nvim-dap-ui',
		'theHamsta/nvim-dap-virtual-text',
	},
	opts = setup_dap,
	keys = kkeys({
		{
			'<F9>',
			function()
				require('dap').toggle_breakpoint()
			end,
			desc = 'Debug: Toggle breakpoint',
		},
		{
			'<F5>',
			function()
				require('dap').continue()
			end,
			desc = 'Debug: continue',
		},
		{
			'<F6>',
			function()
				require('dap').terminate()
			end,
			desc = 'Debug: terminate',
		},
		{
			'<F7>',
			function()
				require('dap').close()
			end,
			desc = 'Debug: close',
		},
		{
			'<F10>',
			function()
				require('dap').step_over()
				require('KoalaVim.utils.misc').center_screen()
			end,
			desc = 'Debug: step over',
		},
		{
			'<F11>',
			function()
				require('dap').step_into()
				require('KoalaVim.utils.misc').center_screen()
			end,
			desc = 'Debug: step into',
		},
		{
			'<F12>',
			function()
				require('dap').step_out()
				require('KoalaVim.utils.misc').center_screen()
			end,
			desc = 'Debug: set out',
		},
		{
			'<leader>rp',
			function()
				require('KoalaVim.utils.debug').toggle_repl()
			end,
			desc = 'Debug: open repl',
		},
		{
			'<leader>rc',
			function()
				require('dap').run_to_cursor()
			end,
			desc = 'Debug: Run to cursor',
		},
		{
			'<leader>k',
			function()
				require('dapui').eval()
			end,
			desc = 'Debug: evaluate',
		},
	}),
})

-- UI panels for nvim-dap (scopes, watches, breakpoints, stacks, repl)
table.insert(M, {
	'rcarriga/nvim-dap-ui',
	lazy = true, -- Loading with dap-ui
	opts = {
		expand_lines = false,
		layouts = {
			{
				size = 0.15,
				position = 'top',
				elements = {
					'scopes', -- local vars
					'repl',
				},
			},
			{
				size = 0.20,
				position = 'right',
				elements = {
					'watches',
					'breakpoints',
					'stacks',
				},
			},
		},
	},
	-- Replaces the `dap.core` extra's config, opens the ui in a new tab instead
	config = function(_, opts)
		local dapui = require('dapui')
		dapui.setup(opts)

		local debug_tab = nil

		-- Called on both `terminated` and `exited`, close the debug page only once
		local dap_closed = function()
			dapui.close({})
			if debug_tab and vim.api.nvim_tabpage_is_valid(debug_tab) and #vim.api.nvim_list_tabpages() > 1 then
				vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(debug_tab))
			end
			debug_tab = nil

			require('KoalaVim.utils.map').map(
				'n',
				'<RightMouse>',
				'<LeftMouse><cmd>sleep 100m<cr><cmd>lua vim.lsp.buf.hover()<cr>',
				'Trigger hover'
			)
		end

		local dap = require('dap')
		-- Hooks to dap, opens/cloes dap-ui binds rightlick to evaluate
		dap.listeners.after.event_initialized['dapui_config'] = function()
			vim.api.nvim_command('$tabnew') -- $(last) is the debug page
			debug_tab = vim.api.nvim_get_current_tabpage()
			dapui.open({})

			require('KoalaVim.utils.map').map('n', '<RightMouse>', '<LeftMouse><cmd>lua require"dapui".eval()<cr>') -- Trigger hover
		end
		dap.listeners.before.event_terminated['dapui_config'] = function()
			dap_closed()
		end
		dap.listeners.before.event_exited['dapui_config'] = function()
			dap_closed()
		end
	end,
})

-- Don't let mason-nvim-dap override the adapters/configurations KoalaVim sets up (see `setup_dap`)
table.insert(M, {
	'jay-babu/mason-nvim-dap.nvim',
	optional = true,
	opts = {
		handlers = {
			codelldb = function() end,
			cppdbg = function() end,
		},
	},
})

-- Cycle between DAP breakpoints with ]d/[d
table.insert(M, {
	'ofirgall/goto-breakpoints.nvim',
	keys = kkeys({
		{
			']d',
			function()
				require('goto-breakpoints').next()
			end,
			desc = 'Goto next breakpoint',
		},
		{
			'[d',
			function()
				require('goto-breakpoints').prev()
			end,
			desc = 'Goto prev breakpoint',
		},
		{
			']S',
			function()
				require('goto-breakpoints').stopped()
			end,
			desc = 'Goto DAP stopped location',
		},
	}),
})

-- Show variable values as virtual text inline while debugging
table.insert(M, {
	'theHamsta/nvim-dap-virtual-text',
	lazy = true,
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	opts = {
		virt_text_pos = 'eol',
	},
	config = function(_, opts)
		require('nvim-dap-virtual-text').setup(opts)
	end,
})

return M
