local M = {}

local usercmd = require('KoalaVim.utils.cmd')

table.insert(M, {
	'mfussenegger/nvim-dap',
	dependencies = {
		'rcarriga/nvim-dap-ui',
		'theHamsta/nvim-dap-virtual-text',
	},
	config = function()
		local dap = require('dap')
		dap.defaults.fallback.stepping_granularity = 'line'
		--- Signs ---
		-- Sign priority = 11
		-- stylua: ignore start
		vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
		vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapCondBreakpoint', linehl = '', numhl = '' })
		vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
		vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DiagnosticWarn', linehl = '', numhl = '' })
		vim.fn.sign_define('DapStopped', { text = '', texthl = 'DiagnosticInfo', linehl = 'CursorLine', numhl = 'CursorLine' })
		-- stylua: ignore end

		--- Setup Adapaters ---

		-- C/C++/Rust
		dap.configurations.cpp = {
			{
				name = 'Launch file',
				type = 'codelldb',
				request = 'launch',
				program = require('KoalaVim.utils.debug').choose_file,
				cwd = vim.fn.getcwd(),
				stopOnEntry = false,
			},
		}
		-- dap.configurations.c = dap.configurations.cpp -- Debug c with codelldb instead
		dap.configurations.rust = dap.configurations.cpp

		dap.adapters.codelldb = {
			type = 'server',
			port = '${port}',
			executable = {
				command = 'codelldb',
				args = { '--port', '${port}' },
			},
		}

		-- C (remote gdb)
		dap.configurations.c = {
			{
				name = 'Attach to gdbserver :1234',
				type = 'cppdbg',
				request = 'launch',
				MIMode = 'gdb',
				miDebuggerServerAddress = 'localhost:1234',
				miDebuggerPath = 'gdb',
				program = require('KoalaVim.utils.debug').choose_file,
				cwd = vim.fn.getcwd(),
				stopOnEntry = false,
			},
		}

		-- From mason
		dap.adapters.cppdbg = {
			id = 'cppdbg',
			type = 'executable',
			command = 'OpenDebugAD7',
		}

		-- Golang
		dap.configurations.go = {
			{
				name = 'Launch Remote',
				type = 'go',
				request = 'attach',
				mode = 'remote',
				remotePath = '~/go/volumez',
				port = 2345,
				apiVersion = 2,
				cwd = '${workspaceFolder}',
				trace = 'verbose',
			},
		}

		dap.adapters.go = {
			type = 'server',
			host = 'rhel8-6.local',
			port = 2345,
		}

		-- Python
		dap.adapters.python = function(cb, config)
			if config.request == 'attach' then
				local port = (config.connect or config).port
				local host = (config.connect or config).host or '127.0.0.1'
				cb({
					type = 'server',
					port = assert(port, '`connect.port` is required for a python `attach` configuration'),
					host = host,
					options = {
						source_filetype = 'python',
					},
				})
			else
				cb({
					type = 'executable',
					command = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python',
					args = {
						'-m',
						'debugpy.adapter',
					},
					options = {
						source_filetype = 'python',
					},
				})
			end
		end

		dap.configurations.python = {
			{
				-- The first three options are required by nvim-dap
				type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
				request = 'launch',
				name = 'Launch file',

				-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

				program = '${file}', -- This configuration will launch the current file if used.
				args = require('KoalaVim.utils.debug').choose_args,
				python = function()
					-- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
					-- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
					-- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
						return cwd .. '/venv/bin/python'
					elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
						return cwd .. '/.venv/bin/python'
					else
						return 'python'
					end
				end,
			},
		}

		usercmd.create('ClearBreakpoints', 'Debug: clear all breakpoints', function()
			require('dap').clear_breakpoints()
		end, {})

		require('KoalaVim.utils.debug').init()
	end,
	keys = {
		{
			'<F9>',
			function()
				require('dap').toggle_breakpoint()
			end,
			desc = 'Debug: Toggle breakpoint',
		},
		-- TODO: conditional breakpoint
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
	},
})

table.insert(M, {
	'rcarriga/nvim-dap-ui',
	lazy = true, -- Loading with dap-ui
	dependencies = {
		'ofirgall/format-on-leave.nvim',
	},
	config = function()
		local dapui = require('dapui')
		dapui.setup({
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
		})

		local dap_closed = function()
			dapui.close({})
			vim.api.nvim_command('tabclose $') -- $(last) is the debug page

			require('KoalaVim.utils.map').map(
				'n',
				'<RightMouse>',
				'<LeftMouse><cmd>sleep 100m<cr><cmd>lua vim.lsp.buf.hover()<cr>',
				'Trigger hover'
			)

			require('format-on-leave').enable()
		end

		local dap = require('dap')
		-- Hooks to dap, opens/cloes dap-ui binds rightlick to evaluate
		dap.listeners.after.event_initialized['dapui_config'] = function()
			vim.api.nvim_command('$tabnew') -- $(last) is the debug page
			dapui.open({})

			require('KoalaVim.utils.map').map('n', '<RightMouse>', '<LeftMouse><cmd>lua require"dapui".eval()<cr>') -- Trigger hover

			require('format-on-leave').disable()
		end
		dap.listeners.before.event_terminated['dapui_config'] = function()
			dap_closed()
		end
		dap.listeners.before.event_exited['dapui_config'] = function()
			dap_closed()
		end
	end,
})

table.insert(M, {
	-- Cycle breakpoints with ]d/[d
	'ofirgall/goto-breakpoints.nvim',
	keys = {
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
	},
})

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
