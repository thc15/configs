" Globals

set nocompatible              " be iMproved
filetype off                  " required!
let g:mapleader=","

"set rtp+=~/.vim/bundle/vundle
"call vundle#rc()
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" let Vundle manage Vundle
" required!
" Bundle 'gmarik/vundle'

" original repos on github
Plug 'vim-scripts/desert-warm-256'

Plug 'https://github.com/vim-scripts/perl-support.vim.git'
Plug 'https://github.com/altercation/vim-colors-solarized.git'
Plug 'https://github.com/vim-scripts/ctags.vim.git'
Plug 'https://github.com/scrooloose/nerdtree.git'
"Plug 'https://github.com/scrooloose/nerdcommenter.git'
Plug 'https://github.com/majutsushi/tagbar.git'
Plug 'https://github.com/ap/vim-buftabline.git'
Plug 'https://github.com/vim-scripts/cpp.vim.git'
Plug 'https://github.com/vim-scripts/python.vim.git'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/kien/ctrlp.vim.git'
"" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'https://github.com/vim-scripts/clang-complete.git'
Plug 'https://github.com/ervandew/supertab.git'
"Plug 'https://github.com/scrooloose/syntastic.git'
Plug 'https://github.com/vim-scripts/BufOnly.vim.git'
Plug 'https://github.com/vim-scripts/bufferlist.vim.git'
Plug 'mileszs/ack.vim'
Plug 'https://github.com/vhda/verilog_systemverilog.vim.git'
"Plug 'https://github.com/vim-scripts/Conque-GDB.git'
"Plug 'https://github.com/Valloric/YouCompleteMe.git'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""
syntax on

set title
set hlsearch
set incsearch
"set smartcase   " do not use -> * fails to search with class delimiter ::
set ignorecase
set vb t_vb=
"set autochdir
set nobackup
set nowritebackup
set noswapfile
" Don't redraw while executing macros (good performance config)
"set lazyredraw
"set noscrollbind
set scrolloff=5
set hidden
set switchbuf=usetab
set autoindent
set cino+=(0    " indent function args
set expandtab
set bs=2
set ts=4
set shiftwidth=2
set number
set list
set listchars=tab:>-,trail:.,extends:>
set columns=200
set cursorline
set autoread
set autowrite
set wildmenu
set wildmode=list:longest
set ruler
set wrap
"set iskeyword-=:

set paste
set go+=a

" Disable bracketed mode
set t_BE=

""""""""""""""""""""MAPPING""""""""""""""""""""""

noremap <C-Left> :bp <CR>
noremap <C-Right> :bn <CR>

map <C-Middlemouse> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

" Ignore these directories
set wildignore+=*/tmp/*
set wildignore+=*/build/**
set wildignore+=*/obj/**
set wildignore+=*/stubobj/**
set wildignore+=*/debug*/**
set wildignore+=*/.git/**
set wildignore+=*/linux_x86/**
set wildignore+=*.so,*.swp,*.zip,*.o,*.l,*.y,*.a,*.exe,*.gold

set path+=$DEV_ROOT/**

autocmd! bufwritepost .vimrc source %
autocmd filetype python set expandtab
" quickwindow
autocmd FileType qf wincmd J

autocmd FocusLost *.[ch] silent! :wa!
autocmd FocusLost *.[ch]pp silent! :wa!
autocmd! * *.log
autocmd! * *.txt
autocmd! * *.gold

map <F1> :tn <CR>

map <F5> :source $HOME/.vimrc <CR>
map <F6> :! $HOME/utils/update_ctags.sh & <CR>

noremap <C-M> :set columns=235 <CR> :cclose <CR> :TagbarToggle <CR> :wincmd =<CR>
noremap <F11> :set columns=310 <CR>
nnoremap <C-o> :BufOnly <CR>
noremap <F4> :bp<CR>:bd # <CR>
noremap <C-s-t> :vs<bar>:b#<CR>

noremap <F12> :%s/\/\(local_home\\|home\\|remote_home\)\/.*\/defacto\/src/\/defacto\/src/g <CR>
" open header/cpp files
noremap ,h :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow
noremap <F9> :wa <CR> :make -j5 -s -w -C $DEV_ROOT/defacto/src/framework/
"command! -nargs=* Mk silent make -w -C <args> | cwindow 3

vmap cc :s/^/\/\/ /<CR>
vmap cu :s/\v^(\/\/\|#)//<CR>

" Use blackhole register to paste (keeps yanked text)
vmap p "_dP

""""""""""""""""""""COLORS""""""""""""""""""""""
colorscheme desert

hi Pmenu ctermbg=12 guibg=#103010 guifg=NONE
hi DiffText term=reverse cterm=bold ctermbg=12 gui=bold guifg=White guibg=#a02222
hi DiffChange term=reverse cterm=bold ctermbg=12 guifg=White guibg=#173117
"DiffAdd, DiffChange, DiffDelete
hi StatusLine guibg=#8c8e91 guifg=#44484f gui=bold
hi StatusLineNC guibg=#8c8e91 guifg=#44484f gui=bold
hi TabLineFill guibg=#8c9e91 guifg=#14181f gui=bold
hi TabLineSel guibg=#6c6e61 guifg=#14181f gui=bold
hi TabLine guibg=#8c9e91 guifg=#14181f gui=bold
hi CursorLine cterm=bold guifg=NONE guibg=#525252

"""""""""""""""""""" TAGS""""""""""""""""""""""
set tags=$DEV_ROOT/tags;

noremap <C-Rightmouse>  
noremap <C-Leftmouse> 

"""""""""""""""""""" CSCOPE""""""""""""""""""""""
set cscopequickfix=s-,c-,d-,i-,t-,e-

if has("cscope")
 set csprg='/local_home/thomas/soft/local/usr/bin/cscope'
 set csto=1
 set cst
 set csverb
 set cspc=3
 silent cs add $DEV_ROOT/cscope.out
 nmap l :cs find c <C-R>=expand("<cword>")<CR><CR>
 nmap L :cs find s <C-R>=expand("<cword>")<CR><CR>
 set nocst "default use tag shortcuts (C-])
endif

" snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-tab>"
let g:UltiSnipsEditSplit="vertical"

"""""""""""""""""""" CLANG_COMPLETE""""""""""""""""""""""
set omnifunc=
set completefunc=
let g:clang_complete_loaded = 1
"let g:clang_debug = 1
" Disable auto popup, use <Tab> to autocomplete
let g:clang_complete_auto = 1
" Show clang errors in the quickfix window
let g:clang_complete_copen = 1
let g:clang_use_library = 1
let g:clang_library_path='/local_home/thomas/soft/local/usr/lib64/llvm/'
let g:clang_trailing_placeholder = 1
let g:clang_close_preview = 1
let g:clang_auto_select = 1
set conceallevel=2
set concealcursor=vin
" Don't use snippets for function completion
"let g:clang_conceal_snippets=1
"let g:clang_snippets = 1
"let g:clang_snippets_engine = 'clang_complete'
" let g:clang_snippets_engine = 'ultisnips'
let g:clang_complete_patterns = 1
let g:clang_complete_optional_args_in_snippets = 1
" Complete options (disable preview scratch window, longest removed to always show menu)
set completeopt=menu,menuone,preview

" Limit popup menu height
set pumheight=20

"let g:clang_jumpto_declaration_key = ',d'
let g:clang_user_options = '-std=c++11'
"set complete-=i " disable completion from include files

"""""""""""""""""""" SUPERTAB""""""""""""""""""""""
" SuperTab option for context aware completion
" SuperTab completion fall-back 
let g:SuperTabDefaultCompletionType='<c-x><c-u><c-p>'
"let g:SuperTabDefaultCompletionType = "context"

"""""""""""""""""""" YCM""""""""""""""""""""""
"let g:ycm_min_num_of_chars_for_completion = 2
"let g:ycm_collect_identifiers_from_tags_files = 1
"let g:ycm_autoclose_preview_window_after_completion = 1
"let g:ycm_show_diagnostics_ui = 1
"let g:ycm_complete_in_strings = 0
"
"let g:ycm_filetype_whitelist = {
"  \ 'cpp': 1,
"  \ 'python': 1
"  \}
"let g:ycm_filetype_specific_completion_to_disable = {
"        \ 'gitcommit': 1
"        \}

""""""""""""""""""""" SPLITS"""""""""""""""""""""""
set splitbelow
set splitright
nnoremap sb :sbNext <CR>
nnoremap vb <ESC> :vert belowright sbNext<CR> :wincmd =<CR>
nnoremap ve :Vexplore<CR>
nnoremap se :Sexplore<CR>
nnoremap + :50winc +<CR>
nnoremap - :30winc -<CR>

autocmd VimResized * exe "normal \<c-w>="

" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv

""""""""""""""""""" DIFF"""""""""""""""""""""""
nnoremap <C-PageDown> ]c
nnoremap <C-PageUp> [c
"nnoremap <C-u> :diffupdate<CR>
nnoremap <C-g> :diffget<CR>
nnoremap ,g :%diffget<CR>
nnoremap <C-p> :diffput<CR>
nnoremap <C-d> :windo diffthis<CR>

"let g:DiffUnit="Word1"
"let g:DiffColors=323
let g:DiffUpdate=1
let g:DiffModeSync=1

if &diff                             " only for diff mode/vimdiff
"  set diffopt+=filler,iwhite,icase,context:2
  set diffopt=filler,iwhite  ",context:1000000
  set nocursorline
endif
autocmd FilterWritePre * if &diff | setlocal wrap< | endif

""""""""""""""""""""" TAB"""""""""""""""""""""
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_show=1

let g:BufTabLineCurrent="TabLine"  "current window
let g:BufTabLineActive="TabLineSel" "other window


""""""""""""""""""""" Ack"""""""""""""""""""""""""
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" prefix with s: for local script-only functions / a: prefix for arguments
function! s:search(pattern)
  "echom "Command: " . a:pattern
  :execute 'Ack --cpp '. a:pattern.' $DEV_ROOT'
endfunction

"map <F3> :execute "noautocmd vimgrep /" .expand("<cword>") . "/j ../**" <Bar> cw<CR>
"map <F3> :execute "noautocmd Ack /" ."--cpp" .expand("<cword>") . "$DEV_ROOT" <Bar> cw <CR>
map <F3> :execute 'Ack --ignore linux_x86 --cpp <cword> $DEV_ROOT' <CR>
command! -nargs=1 Search call s:search(<f-args>) | lwindow

""""""""""""""""""""" Bufferlist"""""""""""""""""""""""
map <silent> <C-b> :call BufferList()<CR>
let g:BufferListWidth = 30
let g:BufferListMaxWidth = 50

""""""""""""""""""""" CtrlP"""""""""""""""""""""""
let g:ctrlp_map = '<c-f>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_by_filename = 1
let g:ctrlp_max_files = 600
let g:ctrlp_max_depth = 20
let g:ctrlp_use_caching = 1
let g:ctrlp_clear_cache_on_exit = 1
let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'
"let g:ctrlp_lazy_update = 50
"let g:ctrlp_extensions = ['tag', 'buffertag']
let g:ctrlp_switch_buffer = 'E'
let g:ctrlp_regexp = 0
let g:ctrlp_mruf_relative = 1

let g:ctrlp_user_command = '$HOME/soft/local/bin/ag %s -i
      \ --nocolor --nogroup --hidden
      \ --ignore .repo
      \ --ignore .git
      \ --ignore .svn
      \ --ignore .hg
      \ --ignore .DS_Store
      \ --ignore test
      \ --ignore "*tmp*"
      \ --ignore "**/*.pyc"
      \ --ignore "obj"
      \ --ignore "debug*"
      \ --ignore "linux_x86"
      \ --ignore "*.gold"
      \ --ignore "*.v"
      \ -g ""'

let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)|debug|obj|linux_x86$',
  \ 'file': '\v\.(exe|so|dll|bin|o|v|d|a|gold)$',
  \ }

""""""""""""""""" ConqueGDB"""""""""""""""""
let dev_root="$DEV_ROOT"
let g:ConqueTerm_Color = 2         " 1: strip color after 200 lines, 2: always with color
let g:ConqueTerm_CloseOnEnd = 1    " close conque when program ends running
let g:ConqueTerm_StartMessages = 1 " display warning messages if conqueTerm is configured incorrectly

let g:ConqueGdb_SaveHistory = 1
let g:ConqueTerm_Color = 0
let g:ConqueTerm_CloseOnEnd = 1
"let g:ConqueGdb_Leader = ','
"let g:ConqueGdbExe = 'libstar/obj/test/debug64/star_debug64.exe'
let g:ConqueTerm_ReadUnfocused = 1

command! -nargs=*  Ds :ConqueGdb $DEV_ROOT.'libstar/obj/test/debug64/star_debug64.exe'
command! -nargs=*  De :ConqueGdb librtledit/obj/test/debug64/rtledit_debug64.exe
command! -nargs=*  Dc :ConqueGdbCommand <args>

""""""""""""""""" Syntastic"""""""""""""""""
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

""""""""""""""""" NerdTree"""""""""""""""""
"nnoremap <C-n> :NERDTree $DEV_ROOT<CR>
"nnoremap <C-h> :NERDTreeToggle $DEV_ROOT<CR>
"let g:NERDTreeChDirMode = 2
nnoremap <C-h> :TagbarToggle <CR>
nnoremap <C-n> :NERDTreeToggle %:p:h <CR>
" auto chdir
" autocmd BufEnter * silent! lcd %:p:h    break fugitive
let g:NERDTreeMouseMode=3
let g:NERDTreeChDirMode=2
let g:NERDTreeWinSize=35
let g:NERDTreeWinPos="left"

""""""""""""""""" FSExplorer"""""""""""""""""
map <C-e> :Explore %:p:h<CR>

""""""""""" SESSIONS (save and restore)""""""""""""""""
set sessionoptions=blank,buffers ",folds,help,options,localoptions,winsize,tabpages
set sessionoptions+=unix,slash,tabpages,winsize

noremap ss :mksession! ~/.vim/sessions/
noremap rs :so ~/.vim/sessions/

 set gfn=Monospace\ Regular\ 8
