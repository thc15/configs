set nocompatible              " be iMproved
filetype off                  " required!

set rtp+=~/bin/fzf
"call vundle#rc()
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" let Vundle manage Vundle
" required!
" Bundle 'gmarik/vundle'

"" original repos on github
Plug 'https://github.com/altercation/vim-colors-solarized.git'
Plug 'https://github.com/romainl/Apprentice.git'
Plug 'https://github.com/karoliskoncevicius/sacredforest-vim.git'

"" urxvt + tmux
Plug 'https://github.com/christoomey/vim-tmux-navigator.git'
Plug 'https://github.com/vim-scripts/ctags.vim.git'
Plug 'https://github.com/majutsushi/tagbar.git' " error cant open file
Plug 'https://github.com/scrooloose/nerdtree.git'
Plug 'https://github.com/vim-scripts/cpp.vim.git'
Plug 'https://github.com/vim-scripts/python.vim.git'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/airblade/vim-gitgutter.git'
"Plug 'https://github.com/jreybert/vimagit.git'
Plug 'junegunn/fzf.vim'
Plug 'jacquesbh/vim-showmarks'
Plug 'https://github.com/AndrewRadev/linediff.vim.git'
Plug 'https://github.com/machakann/vim-highlightedyank.git'
Plug 'https://github.com/tpope/vim-obsession.git'
Plug 'https://github.com/will133/vim-dirdiff.git'
""" Snippets
"Plug 'SirVer/ultisnips'
"Plug 'honza/vim-snippets'
"Plug 'https://github.com/vim-scripts/BufOnly.vim.git'
""Plug 'https://github.com/vim-scripts/bufferlist.vim.git'
Plug 'mileszs/ack.vim'
Plug 'vim-utils/vim-husk'
Plug 'https://github.com/bogado/file-line.git'
Plug 'https://github.com/vim-scripts/DoxygenToolkit.vim.git'
Plug 'https://github.com/vim-scripts/OmniCppComplete.git'
Plug 'https://github.com/ervandew/supertab.git'
Plug 'vim-scripts/Align'
Plug 'https://github.com/vim-scripts/mru.vim.git'
"Plug 'itchyny/lightline.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'https://github.com/ap/vim-buftabline.git'
Plug 'puremourning/vimspector'
"Plug 'https://github.com/junegunn/vim-github-dashboard.git'
Plug 'https://github.com/habamax/vim-rst.git'

"LSC
"Plug 'natebosch/vim-lsc'

"LSP
Plug 'prabirshrestha/vim-lsp'
Plug 'piec/vim-lsp-clangd'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""
set notitle   " autorename tmux window title
set hlsearch
set incsearch
"set smartcase   " do not use -> * fails to search with class delimiter ::
set ignorecase
set vb t_vb=
set autochdir
set nobackup
set nowritebackup
set noswapfile
" Don't redraw while executing macros (good performance config)
"set lazyredraw
"set noscrollbind
set scrolloff=5
set hidden
set switchbuf=usetab
"set autoindent
set cino+=(0    " indent function args
set expandtab
set bs=2
set ts=4
set shiftwidth=0
set number
set list
set listchars=tab:▸\ ,trail:.,extends:>
set autoread
set autowrite
set wildmenu
set wildmode=list:longest
set wildmode=list:full
set ruler
set wrap
"set iskeyword-=:
"set columns=330
set colorcolumn=80
"set undofile
set re=1
"set timeoutlen=100
set laststatus=2
set encoding=utf-8
"set updatetime=15000

" Default to not read-only in vimdiff
set noro

"set clipboard=unnamed
set clipboard=unnamedplus

"make ctrl arrow ok
set term=xterm-256color
set termguicolors
set t_Co=256
"let &t_8f = "\<Esc>[38:2:%lu:%lu:%lum"
"let &t_8b = "\<Esc>[48:2:%lu:%lu:%lum"

let g:solarized_termcolors=256
let g:solarized_termtrans = 0
let g:solarized_degrade = 1
let g:solarized_bold = 1
let g:solarized_underline = 0
let g:solarized_italic =  1
let g:solarized_contrast = "low"
let g:solarized_visibility = "high"
let g:solarized_extra_hi_groups = 1

"set paste " Do not set paste option for supertab
" Visual sel to clipboard
set go+=a

" Disable bracketed mode
set t_BE=
set mouse=a
set t_ut=

"profile start profile.log
"profile func *
"profile file *
"""""""""""""""""""""MAPPING""""""""""""""""""""""
let g:mapleader = ","
inoremap jk <Esc>
xnoremap <leader>p "_dP

" Ignore these directories
set wildignore+=*/tmp/*
set wildignore+=*/build*/**
set wildignore+=*/obj/**
set wildignore+=*/bin/**
set wildignore+=*/stubobj/**
set wildignore+=*/debug*/**
set wildignore+=*/.git/**
set wildignore+=*/linux_x86/**
set wildignore+=*.so,*.swp,*.zip,*.o,*.l,*.y,*.a,*.exe,*.gold,*.out,*.dox

"set path+=$DEV_ROOT/**

autocmd! bufwritepost .vimrc* source %
autocmd BufReadPost,FileReadPost,BufNewFile,BufEnter * call system("tmux rename-window " . expand("%:t"))
" quickwindow
autocmd FileType qf wincmd J

autocmd FocusLost,BufLeave,WinLeave *  silent! :wa!
autocmd BufEnter * stopinsert
"autocmd CursorHoldI * stopinsert
au FocusGained,BufEnter * :checktime

"autocmd FocusLost,BufLeave .* silent! :wa!
"autocmd FocusLost,BufLeave *.[ch] silent! :wa!
"autocmd FocusLost,BufLeave *.[ch]pp silent! :wa!
"autocmd FocusLost,BufLeave *.sv silent! :wa!
"autocmd FocusLost,BufLeave *.log silent! :wa!
"autocmd FocusLost,BufLeave *.txt silent! :wa!
"autocmd FocusLost,BufLeave *.py silent! :wa!
autocmd! * *.log
autocmd! * *.txt
autocmd! * *.gold
autocmd BufEnter * silent! nested :DoShowMarks!
autocmd BufEnter * silent! nested lcd %:p:h  "  break fugitive

autocmd BufRead,BufNewFile *.py,*.pyw,*.sh set shiftwidth=4
autocmd BufRead,BufNewFile *.py,*.pyw,*.sh set expandtab
autocmd BufRead,BufNewFile *.rb set expandtab
autocmd BufRead,BufNewFile *.[ch] set noexpandtab
autocmd BufRead,BufNewFile *.yaml set noexpandtab
autocmd BufRead,BufNewFile *.dtsi set noexpandtab
autocmd BufRead,BufNewFile *.robot,*.resource setf robot
"au InsertEnter * let updaterestore=&updatetime | set updatetime=2000
"au InsertLeave * let &updatetime=updaterestore

augroup Binary
  au!
  au BufReadPre  *.bin,*.elf let &bin=1
  au BufReadPost *.bin,*.elf if &bin | %!xxd
  au BufReadPost *.bin,*.elf set ft=xxd | endif
  au BufWritePre *.bin,*.elf if &bin | %!xxd -r
  au BufWritePre *.bin,*.elf endif
  au BufWritePost *.bin,*.elf if &bin | %!xxd
  au BufWritePost *.bin,*.elf set nomod | endif
augroup END

nmap <C-Middlemouse> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
"nmap <c-d> :cs find g <c-r>=expand("<cword>")<cr><cr>

" open header/cpp files
" noremap ,h :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
function! SwitchSourceHeader()
  if (expand ("%:e") == "c")
    let f = system('find ../ -type f -name ' . expand('%:t:r').'.h')
    execute 'edit '.f
  else
    let f = system('find ../ -type f -name ' . expand('%:t:r').'.c')
    execute 'edit '.f
  endif
endfunction

nmap <leader>h :call SwitchSourceHeader()<CR>

autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

vmap cc :s/^/\/\/ /<CR>
vmap cu :s/\v^(\/\/\|#)//<CR>

""""""""""""""""""" DIFF"""""""""""""""""""""""
nnoremap <C-PageDown> ]c
nnoremap <C-PageUp> [c
nnoremap <leader>g :%diffget<CR>

"let g:DiffUnit="Word1"
"let g:DiffColors=323
let g:DiffUpdate=1
let g:DiffModeSync=1
"hi DiffAdd      gui=none    guifg=NONE          guibg=#bada9f
"hi DiffChange   gui=none    guifg=NONE          guibg=#e5d5ac
"hi DiffDelete   gui=bold    guifg=#ff8080       guibg=#ffb0b0

" only for diff mode/vimdiff
if &diff
"  set diffopt+=filler,iwhite,icase,context:2
  set diffopt=filler  ",context:1000000
  set nocursorline
  set columns=200
endif
autocmd FilterWritePre * if &diff | setlocal wrap< | endif

let g:linediff_first_buffer_command  = 'new'
let g:linediff_further_buffer_command = 'vertical new'


"Ultisnips Settings
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window
let g:UltiSnipsEditSplit="vertical"

""""""""""""""""""""" Complete LSP"""""""""""""""""""""
let g:lsp_settings = {
			\  'clangd': {'cmd': ['clangd']}
			\ }
let g:asyncomplete_auto_popup = 0
let g:lsp_diagnostics_enabled = 0



""""""""""""""""""""" LSC"""""""""""""""""""""
"let g:lsc_auto_map = {'Completion': 'omnifunc'}
"let g:lsc_enable_autocomplete = v:false
"let g:lsc_server_commands = {
"\  'c': {
"\    'command': 'clangd',
"\    'log_level': -1,
"\    'suppress_stderr': v:true,
"\  },
"\  'cpp': {
"\    'command': 'clangd',
"\    'log_level': -1,
"\    'suppress_stderr': v:true,
"\  },
"\}
"
"let g:lsc_enable_autocomplete = v:false
"" Use all the defaults (recommended):
"let g:lsc_auto_map = v:true
"
"" Apply the defaults with a few overrides:
"let g:lsc_auto_map = {'defaults': v:true, 'FindReferences': '<leader>r'}
"
"" Setting a value to a blank string leaves that command unmapped:
"let g:lsc_auto_map = {'defaults': v:true, 'FindImplementations': ''}
"
"" ... or set only the commands you want mapped without defaults.
"" Complete default mappings are:
"let g:lsc_auto_map = {
"\ 'GoToDefinition': '<C-]>',
"\ 'GoToDefinitionSplit': ['<C-W>]', '<C-W><C-]>'],
"\ 'FindReferences': 'gr',
"\ 'NextReference': '<C-n>',
"\ 'PreviousReference': '<C-p>',
"\ 'FindImplementations': 'gI',
"\ 'FindCodeActions': 'ga',
"\ 'Rename': 'gR',
"\ 'ShowHover': v:true,
"\ 'DocumentSymbol': 'go',
"\ 'WorkspaceSymbol': 'gS',
"\ 'SignatureHelp': 'gm',
"\ 'Completion': 'completefunc',
"\}
"
""""""""""""""""""""" TAB"""""""""""""""""""""
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_show=2

"let g:BufTabLineCurrent="TabLineSel"  "current window
"let g:BufTabLineActive="TabLine" "other window

""""""""""""""""""""" AIRLINE"""""""""""""""""""""
let g:airline_statusline_ontop=0
let g:airline_stl_path_style = 'short'


""""""""""""""""""""" Ack"""""""""""""""""""""""""
" prefix with s: for local script-only functions / a: prefix for arguments
function! s:search(pattern)
  "echom "Command: " . a:pattern
  :execute 'Ack --cpp '. a:pattern.' $DEV_ROOT'
endfunction

map <F3> :execute "noautocmd vimgrep /" .expand("<cword>") . "/j ../**" <Bar> cw<CR>
map <F4> :bdelete <CR>
"map <F3> :execute "noautocmd Ggrep " .expand("<cword>") <Bar> cw<CR><CR>
command! -nargs=1 Search call s:search(<f-args>) | lwindow



set fillchars+=stl:\ ,stlnc:\

""""""""""""""""""""" FZF"""""""""""""""""""""""
" - Popup window
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
" - down / up / left / right
let g:fzf_layout = { 'down': '40%' }
let g:fzf_history_dir = '~/.fzf/share/fzf-history'
let g:fzf_preview_window = ['right:50%', 'ctrl-/']
let g:fzf_preview_window = ['up:40%:hidden', 'ctrl-/']

let g:fzf_buffers_jump = 0
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
let g:fzf_tags_command = 'ctags -R'
let g:fzf_commands_expect = 'alt-enter,ctrl-x'

command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

nnoremap <silent> <C-f> :Files<CR>
nnoremap <silent> <Leader>f :Ag<CR>
nnoremap <silent> <Leader>b :Buffers<CR>
nnoremap <silent> <Leader>g :GFiles<CR>
nnoremap <silent> <Leader>c :Commits<CR>

""""""""""""""""" Syntastic"""""""""""""""""
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0
let g:syntastic_c_checkers=['make','splint']


""""""""""""""""" NerdTree"""""""""""""""""
"nnoremap <C-n> :NERDTree $DEV_ROOT<CR>
"nnoremap <C-h> :NERDTreeToggle $DEV_ROOT<CR>
"let g:NERDTreeChDirMode = 2
"nnoremap <C-> :TagbarToggle <CR>
nnoremap <C-e> :chdir %:p:h <CR> :NERDTreeCWD <CR>
nnoremap <C-d> :NERDTreeToggle <CR>

let g:tagbar_silent = 1

" auto chdir
let g:NERDTreeMouseMode=3
let g:NERDTreeChDirMode=2
let g:NERDTreeWinSize=35
let g:NERDTreeWinPos="left"
let NERDTreeDirArrows = 1
let NERDTreeQuitOnOpen = 3

"""""""""""""""""""" TAGS""""""""""""""""""""""
set tags=./tags;,tags;,.tags
nnoremap <leader>t :tag <c-r><c-w><cr>
"C-t to go back

"""""""""""""""""""" AUTOTAGS"""""""""""""""""""""
let g:autotagTagsFile=".tags"
let g:autotagStopAt=$HOME . "/work"

"""""""""""""""""""" TMUX"""""""""""""""""""""
" Write all buffers before navigating from Vim to tmux pane
let g:tmux_navigator_save_on_switch = 2
let g:tmux_navigator_disable_when_zoomed = 1

let g:tmux_navigator_no_mappings = 1
noremap <silent> <C-Left> :TmuxNavigateLeft<cr>
noremap <silent> <C-Right> :TmuxNavigateRight<cr>
noremap <silent> <C-Down> :TmuxNavigateDown<cr>
noremap <silent> <C-Up> :TmuxNavigateUp<cr>
noremap <silent> <C-BS> :TmuxNavigatePrevious<cr>

noremap <C-h> :bp <CR>
noremap <C-l> :bn <CR>

""""""""""""""""""""" SPLITS"""""""""""""""""""""""
set splitbelow
set splitright
"noremap sb :sbNext <CR>
nnoremap <F2> <ESC> :vert belowright sbNext<CR> :cclose <CR> :wincmd =<CR>
"nnoremap + :50winc +<CR>
"nnoremap - :30winc -<CR>

autocmd VimResized * exe "normal \<c-w>="

" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv

""""""""""""""""" DoxyToolkit""""""""""""""""
let g:DoxygenToolkit_compactDoc = "yes"
let g:C_UseTool_doxygen = 'yes'

""""""""""" SESSIONS (save and restore)""""""""""""""""
set sessionoptions=blank,buffers ",folds,help,options,localoptions,winsize,tabpages
set sessionoptions+=unix,slash,tabpages,winsize

noremap ss :mksession! ~/.vim/sessions/
noremap rs :so ~/.vim/sessions/

set enc=utf-8
syntax enable

colorscheme apprentice
set bg=dark
set cursorline
hi clear CursorLine
"hi CursorLine guibg=Grey40 term=none cterm=none
highlight CursorLine cterm=bold
hi ColorColumn ctermbg=grey guibg=Grey30

