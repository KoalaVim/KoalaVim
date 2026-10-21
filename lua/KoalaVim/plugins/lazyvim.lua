local M = {}
-- LazyVim plugins that KoalaVim replaces with its own, one owner per concern.
-- (LazyVim's snacks modules that KoalaVim replaces are disabled in the snacks spec, see `plugins/editor.lua`)

-- Motions: leap + flit
table.insert(M, { 'folke/flash.nvim', enabled = false })

-- Auto pairs: nvim-autopairs
table.insert(M, { 'nvim-mini/mini.pairs', enabled = false })

-- Commentstring: Comment.nvim + nvim-ts-context-commentstring
table.insert(M, { 'folke/ts-comments.nvim', enabled = false })

-- Search and replace: nvim-spectre + muren
table.insert(M, { 'MagicDuck/grug-far.nvim', enabled = false })

-- File explorer: nvim-tree.
-- LazyVim imports its default `editor.snacks_explorer` extra on its own (`vim.g.lazyvim_explorer` accepts only
-- `snacks`/`neo-tree`), so turn off the module and drop the keys it adds instead (`explorer` is disabled in the snacks
-- spec in `plugins/editor.lua`).
table.insert(M, {
	'folke/snacks.nvim',
	keys = {
		{ '<leader>fe', false },
		{ '<leader>fE', false },
		{ '<leader>e', false },
		{ '<leader>E', false },
	},
})

return M
