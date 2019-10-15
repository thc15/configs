source $HOME/.vimrc_common

""""""""""""""""""""COLORS""""""""""""""""""""""
"set gfn=Monospace\ 8
set guifont=Bitstream\ Vera\ Sans\ Mono\ 8

set background=dark
colorscheme desert

" On colorscheme change force reset of cursorline
augroup CustomCursorLine
au!
au ColorScheme * :hi! CursorLine ctermbg=333
au ColorScheme * :hi! ColorColumn ctermbg=darkgray guibg=gray22
augroup END

hi Pmenu ctermbg=grey guibg=grey33

