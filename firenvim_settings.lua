-- TODO: use this config
local cmd = vim.cmd
local opt = vim.opt
-- use { 'glacambre/firenvim', run = function() vim.fn['firenvim#install'](0) end } -- NVIM in firefox

opt.laststatus = 0
cmd([[
let g:firenvim_config = {
    \ 'globalSettings': {
        \ 'alt': 'all',
    \  },
    \ 'localSettings': {
        \ '.*': {
            \ 'cmdline': 'neovim',
            \ 'content': 'text',
            \ 'priority': 0,
            \ 'selector': 'textarea',
            \ 'takeover': 'never',
        \ },
    \ }
\ }
]])
cmd([[
function! SetLinesForFirefox(timer)
    set lines=28 columns=110 laststatus=0
endfunction

function! OnUIEnter(event) abort
    set guifont=Mono:h20
    call timer_start(100, function("SetLinesForFirefox"))
endfunction

autocmd UIEnter * call OnUIEnter(deepcopy(v:event))
]])
