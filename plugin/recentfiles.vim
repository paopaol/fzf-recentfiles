if !has('nvim-0.5')
echohl Error
echohl clear
finish
endif

if exists('g:loaded_recentfiles') | finish | endif
let g:loaded_recentfiles = 1

" " FzfLua builtin lists
" function! s:fzflua_complete(arg,line,pos)
" let l:builtin_list = luaeval('vim.tbl_keys(require("fzf-lua"))')

" let list = [l:builtin_list]
" let l = split(a:line[:a:pos-1], '\%(\%(\%(^\|[^\\]\)\\\)\@<!\s\)\+', 1)
" let n = len(l) - index(l, 'FzfLua') - 2

" return join(list[0],"\n")
" endfunction

autocmd BufEnter * lua require('recentfiles').update_history()

command! FzfRecentFiles lua require'recentfiles'.fzf_recentfiles()
