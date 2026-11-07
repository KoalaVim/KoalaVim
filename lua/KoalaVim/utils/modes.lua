local M = {}

local health = require('KoalaVim.health')

function M.load(mode, args)
	args = args or ''
	if not M._modes[mode] then
		health.error(string.format("Failed to load `%s` mode (doesn't exists)", mode))
		return
	end

	-- Load mode
	return M._modes[mode](args)
end

local function git_mode(args)
	require('KoalaVim.utils.git').show_tree(args)
	require('KoalaVim.utils.git').show_status()
end

local function git_tree_mode(args)
	require('KoalaVim.utils.git').show_tree(args)
end

local function git_diff_mode(args)
	require('KoalaVim.utils.git').show_diff(args)

	vim.schedule(function()
		vim.cmd('tabonly') -- Close other tab pages
	end)
end

local function ai_mode(args)
	local general = require('KoalaVim.utils.ai.general')
	local parts = vim.split(vim.trim(args or ''), '%s+', { trimempty = true })
	local tool = table.remove(parts, 1)
	if tool and tool ~= '' then
		general.set_default_tool(tool)

		-- cswap: first arg is the account (goes before `--`), the rest are claude params.
		-- A leading flag means no account was given.
		if tool == 'cswap' and parts[1] and not vim.startswith(parts[1], '-') then
			local config = require('sidekick.config')
			config.cli.tools.cswap = require('KoalaVim.utils.ai.claude').cswap_tool(table.remove(parts, 1))
		end
	else
		-- No tool given: fall back to `ai.default_tool`
		tool = general.get_default_tool()
	end

	-- On restart, resume the previous claude conversation unless args already pick a session
	if vim.env.KOALA_RESTART and tool and general.tool_agent(tool) == 'claude' then
		local resumes = { ['--continue'] = true, ['-c'] = true, ['--resume'] = true, ['-r'] = true }
		local has_resume = vim.iter(parts):any(function(p)
			return resumes[p] or vim.startswith(p, '--resume=')
		end)
		if not has_resume then
			table.insert(parts, '--continue')
		end
	end

	if tool and not vim.tbl_isempty(parts) then
		local config = require('sidekick.config')
		local tool_config = config.cli.tools[tool]
		if not tool_config then
			health.error(('Unknown Sidekick tool `%s`'):format(tool))
			return
		end

		local cmd = vim.deepcopy(config.get_tool(tool).cmd)
		vim.list_extend(cmd, parts)
		tool_config.cmd = cmd
	end

	general.with_default_tool(function(opts)
		require('sidekick.cli.state').with(function(state, _, created)
			if state.session.backend == 'herdr' and not state.terminal and not created then
				return
			end
			if state.terminal then
				vim.defer_fn(function()
					local win = state.terminal.win
					if win and vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_win_call(win, function()
							general.zoom_sidekick(state, true)
						end)
					end
				end, 200)
			else
				general.zoom_sidekick(state, true)
			end
		end, { attach = true, show = true, focus = true, filter = { name = opts.name } })
	end)
end

M._modes = {
	git = git_mode,
	git_tree = git_tree_mode,
	git_diff = git_diff_mode,
	ai = ai_mode,
}

return M
