if !has('nvim-0.5')
echohl Error
echohl clear
finish
endif

if exists('g:loaded_recentfiles') | finish | endif
let g:loaded_recentfiles = 1


autocmd BufEnter * lua require('recentfiles').update_history()

command! FzfRecentFiles lua require'recentfiles'.fzf_recentfiles()
