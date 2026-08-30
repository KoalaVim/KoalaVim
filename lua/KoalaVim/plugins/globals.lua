-- TODO: find a better solutions for globals.lua
local M = {}

---@alias LspServerResolver fun(conf: KoalaVim.Conf.lsp): string?, table?

LSP_SERVERS = {}

---@param resolver LspServerResolver
function LSP_SERVER(resolver)
	table.insert(LSP_SERVERS, resolver)
end
NONE_LS_SRCS = {}
HYDRAS = {}
CONFORM_FORMATTERS = {}
HELPERS = {}
--TODO: some help files are ghost files
GHOST_FILETYPES = { 'fugitive', 'NvimTree' }

return M
