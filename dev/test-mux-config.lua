-- Run from the repository root with: nvim --headless -u NONE -l dev/test-mux-config.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
package.loaded['KoalaVim.health'] = { warn = error }
local conf = require('KoalaVim.conf')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
conf.get_kvim_conf = function()
	return 'default_kvim.conf'
end
conf.get_user_conf = function()
	return root .. '/user.json'
end
conf.get_env_conf = function()
	return root .. '/env.json'
end
conf.get_repo_conf = function()
	return root .. '/repo.json'
end
local function load(user, repo, expected, env)
	vim.fn.writefile({ vim.json.encode(env or {}) }, conf.get_env_conf())
	vim.fn.writefile({ vim.json.encode(user) }, conf.get_user_conf())
	vim.fn.writefile({ vim.json.encode(repo) }, conf.get_repo_conf())
	conf.load()
	local ai = require('KoalaVim').conf.ai
	assert(ai.mux.split == expected)
	assert(ai.mux.editor == false)
	assert(ai.mux_split == nil)
end
load({}, {}, false)
load({ ai = { mux_split = true } }, {}, true)
load({ ai = { mux = { split = true } } }, { ai = { mux_split = false } }, false)
load({ ai = { mux_split = true, mux = { split = false } } }, {}, false)
load({ ai = { mux = { split = false } } }, { ai = { mux_split = true } }, true)
load({ ai = { mux = { split = false } } }, {}, true, { ai = { mux_split = true } })
load({}, { ai = { mux_split = false } }, false, { ai = { mux = { split = true } } })
load({}, {}, false, { ai = { mux_split = true, mux = { split = false } } })
vim.fn.delete(root, 'rf')
print('Mux defaults are disabled; legacy mux_split migrates with repo/user precedence preserved')
