source $HOME/.vimrc_common

"""""""""""""""""""""COLORS""""""""""""""""""""""
set term=xterm-256color
if &term =~ '256color'
  " disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
  set t_Co=256
endif

set ttymouse=sgr

set background=dark
"set termguicolors
let g:vitality_tmux_can_focus = 1
colorscheme PaperColor
let g:PaperColor_Theme_Options = {
    \   'theme': {
    \     'default': {
    \       'allow_bold': 1,
    \     }
    \   }
    \ }
""  if &term =~ '^screen'
""    " tmux will send xterm-style keys when its xterm-keys option is on
""    execute "set <xHome>=\e[1;*H"
""    execute "set <Home>=\e[1;*H"
""  endif
"
"execute "set <xUp>=\e[1;*A"
"execute "set <xDown>=\e[1;*B"
"execute "set <xRight>=\e[1;*C"
"execute "set <xLeft>=\e[1;*D"
"colorscheme desert
" On colorscheme change force reset of cursorline
augroup CustomCursorLine
au!
au ColorScheme * :hi! CursorLine ctermbg=Black
au ColorScheme * :hi! ColorColumn ctermbg=darkgray guibg=gray22
augroup END

