local M = {}

table.insert(M, {
	'aklt/plantuml-syntax',
})

table.insert(M, {
	'weirongxu/plantuml-previewer.vim',
	ft = {
		'iuml',
		'plantuml',
		'pu',
		'puml',
		'wsd',
	},
	config = function()
		-- create OpenBrowser vim func instead of 'tyru/open-browser.vim'
		_G.open_browser = function(url)
			require('open.system_open').open(url)
		end
		-- stylua: ignore start
		vim.api.nvim_exec2([[
		function! OpenBrowser(cmd)
			call v:lua.open_browser(a:cmd)
		endfunction
		]], {})
		-- stylua: ignore end
	end,
})

return M
