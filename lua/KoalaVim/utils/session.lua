local M = {}

function M.list_sessions()
	local fzy_sorter = require('telescope.sorters').get_fzy_sorter()
	local path_utils = require('KoalaVim.utils.path')

	local current_cwd_session_pattern = '^' .. vim.fn.getcwd()
	local session_sorter = require('telescope.sorters').Sorter:new({
		scoring_function = function(a, prompt, line)
			local fzy_score = fzy_sorter.scoring_function(a, prompt, line)
			if fzy_score < 0 then
				return fzy_score
			end

			if line:match(current_cwd_session_pattern) then
				return 0
			end
			return fzy_score
		end,

		discard = true,
		highlighter = fzy_sorter.highlighter,
	})

	local home_dir_regex = '^' .. vim.loop.os_homedir()
	local get_session_finder = function()
		local sessions = require('possession.query').as_list()
		return require('telescope.finders').new_table({
			results = sessions,
			entry_maker = function(entry)
				local unescaped_name = path_utils.unescape_dir(entry.name)
				return {
					value = entry,
					display = unescaped_name:gsub(home_dir_regex, '~'),
					ordinal = unescaped_name,
				}
			end,
		})
	end

	require('telescope').extensions.possession.list({
		prompt_title = 'Choose Session (sorted by cwd and frequency)',
		previewer = false,
		layout_config = {
			height = 0.30,
			width = 0.40,
		},
		sorter = session_sorter,
		finder = get_session_finder(),
		layout_strategy = 'center',
		sorting_strategy = 'ascending', -- From top
	})
end

return M
