-- Run from KoalaVim: nvim --headless -u NONE -l dev/test-cmp-fuzzy-herdr.lua
local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
for _, name in ipairs({ 'nvim-cmp', 'cmp-fuzzy-buffer', 'cmp-fuzzy-herdr' }) do
	vim.opt.rtp:append(root .. '/../' .. name)
end
package.preload.lspkind = function()
	return {
		cmp_format = function()
			return function(_, item)
				return item
			end
		end,
	}
end
package.preload['cmp-lspkind-priority'] = function()
	return { setup = function() end, compare = function() end }
end
package.preload.snippy = function()
	return {}
end
package.preload['ofirkai.plugins.nvim-cmp'] = function()
	return { kind_icons = {}, window = {} }
end
local cmp = require('cmp')
local specs = dofile(root .. '/lua/KoalaVim/plugins/autocomplete.lua')
local main, buffer, herdr, crates, git
for _, spec in ipairs(specs) do
	if spec[1] == 'hrsh7th/nvim-cmp' then
		main = spec
	end
	if spec[1] == 'KoalaVim/cmp-fuzzy-buffer' then
		buffer = spec
	end
	if spec[1] == 'KoalaVim/cmp-fuzzy-herdr' then
		herdr = spec
	end
	if spec[1] == 'saecki/crates.nvim' then
		crates = spec
	end
	if spec[1] == 'petertriho/cmp-git' then
		git = spec
	end
end
assert(vim.tbl_contains(buffer.dependencies, 'KoalaVim/cmp-fuzzy-herdr'))
assert(vim.tbl_contains(herdr.dependencies, 'KoalaVim/fuzzy.nvim'))
main.config(nil, {})
local function verify(sources, max, expected_priority)
	local found = {}
	for _, s in ipairs(sources) do
		found[s.name] = s
	end
	assert(found.fuzzy_buffer and found.fuzzy_herdr)
	assert(found.fuzzy_herdr.max_item_count == max)
	assert(found.fuzzy_herdr.priority == expected_priority)
	return found
end
local found = verify(cmp.get_config().sources, 10, 100)
assert(found.fuzzy_buffer.priority == 150 and found.fuzzy_dictionary.priority == 50)
local config = require('cmp.config')
verify(config.cmdline['/'].sources, 15, nil)
for _, s in ipairs(config.cmdline[':'].sources) do
	assert(s.name ~= 'fuzzy_herdr')
end
package.preload.crates = function()
	return { setup = function() end }
end
crates.config()
verify(config.filetypes.toml.sources, 15, nil)
package.preload.cmp_git = function()
	return { setup = function() end }
end
git.config()
verify(config.filetypes.dapui_watches.sources, 15, 100)
assert(vim.tbl_contains(cmp.get_config().sorting.comparators, require('cmp_fuzzy_herdr.compare')))
print('KoalaVim integration: dependencies, four source contexts, priorities and comparator passed')
vim.cmd('qa!')
