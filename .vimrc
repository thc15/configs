" Globals

set nocompatible              " be iMproved
filetype off                  " required!
let g:mapleader=","

"set rtp+=~/.vim/bundle/vundle
let $VIM=$HOME . "/bin/vim"
let $VIMRUNTIME=$HOME . "/softs/vim/runtime"
set runtimepath^=$VIMRUNTIME
set helpfile=$VIMRUNTIME/doc/help.txt

"call vundle#rc()
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" let Vundle manage Vundle
" required!
" Bundle 'gmarik/vundle'

" original repos on github
Plug 'vim-scripts/desert-warm-256'
Plug 'https://github.com/altercation/solarized'
Plug 'https://github.com/altercation/vim-colors-solarized.git'
Plug 'tsiemens/vim-aftercolors'
Plug 'NLKNguyen/papercolor-theme'
Plug 'https://github.com/sheerun/vim-wombat-scheme.git'


" urxvt + tmux
Plug 'https://github.com/akracun/vitality.vim.git'
Plug 'https://github.com/drmikehenry/vim-fixkey.git'
Plug 'https://github.com/vim-scripts/perl-support.vim.git'
Plug 'https://github.com/vim-scripts/ctags.vim.git'
Plug 'https://github.com/craigemery/vim-autotag.git'
Plug 'https://github.com/majutsushi/tagbar.git'
"Plug 'https://github.com/chazy/cscope_maps.git'
Plug 'https://github.com/scrooloose/nerdtree.git'
"Plug 'https://github.com/scrooloose/nerdcommenter.git'
Plug 'https://github.com/ap/vim-buftabline.git'
Plug 'https://github.com/vim-scripts/cpp.vim.git'
Plug 'https://github.com/vim-scripts/python.vim.git'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/jreybert/vimagit.git'
Plug 'https://github.com/kien/ctrlp.vim.git'
Plug 'jacquesbh/vim-showmarks'
Plug 'https://github.com/AndrewRadev/linediff.vim.git'
Plug 'https://github.com/machakann/vim-highlightedyank.git'
"" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'https://github.com/ervandew/supertab.git'
Plug 'https://github.com/vim-scripts/BufOnly.vim.git'
Plug 'https://github.com/vim-scripts/bufferlist.vim.git'
Plug 'mileszs/ack.vim'
"Plug 'https://github.com/vim-scripts/Conque-GDB.git'
"Plug 'https://github.com/Valloric/YouCompleteMe.git'
Plug 'https://github.com/bogado/file-line.git'
Plug 'https://github.com/vim-scripts/DoxygenToolkit.vim.git'

Plug 'https://github.com/vim-ruby/vim-ruby.git'
"Plug 'https://github.com/davidhalter/jedi-vim.git'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'https://github.com/vim-scripts/OmniCppComplete.git'
Plug 'vim-scripts/Align'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""
set title
set hlsearch
set incsearch
"set smartcase   " do not use -> * fails to search with class delimiter ::
set ignorecase
set vb t_vb=
"set autochdir
set nobackup
set nowritebackup
"set backupdir=/work1/tcostis/tmp/vim_bck
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
set ts=8
set shiftwidth=0
set number
set list
set listchars=tab:>-,trail:.,extends:>
"set columns=200
set autoread
set autowrite
set wildmenu
"set wildmode=list:longest
set wildmode=list:full
set ruler
set wrap
set cursorline
"set iskeyword-=:
set colorcolumn=80
"set undofile

set clipboard=unnamed
set clipboard+=unnamedplus

set paste
set go+=a

" Disable bracketed mode
set t_BE=

""""""""""""""""""""MAPPING""""""""""""""""""""""

noremap <C-Left> :bp <CR>
noremap <C-Right> :bn <CR>

nmap <C-Middlemouse> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
"nmap <c-d> :cs find g <c-r>=expand("<cword>")<cr><cr>

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

set path+=$DEV_ROOT/**

autocmd! bufwritepost .vimrc source %
" quickwindow
autocmd FileType qf wincmd J

function! SaveFile ()
    set buftype=
    write
endfunction
autocmd BufWritePre * :call SaveFile()
autocmd FocusLost,BufLeave *  silent! :wa!

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

autocmd BufRead,BufNewFile *.py,*pyw set shiftwidth=4
autocmd BufRead,BufNewFile *.py,*.pyw set expandtab
autocmd BufRead,BufNewFile *.rb set expandtab
autocmd BufRead,BufNewFile *.[ch] set noexpandtab
autocmd BufRead,BufNewFile *.yaml set noexpandtab
autocmd BufRead,BufNewFile *.dtsi set noexpandtab

map <F1> :tn <CR>

map <F2> :source $HOME/.vimrc <CR>
"map <F6> :! $HOME/utils/update_ctags.sh & <CR>

noremap <C-M> :set columns=210 <CR> :cclose <CR> :wincmd =<CR>
noremap <F11> :set columns=310 <CR>
nnoremap <C-o> :BufOnly <CR>
noremap <F4> :bp<CR>:bd # <CR>
noremap <C-s-t> :vs<bar>:b#<CR>
noremap <F8> :vertical wincmd f<CR>
noremap <F6> :browse oldfiles!<CR>

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
noremap <F9> :wa <CR> :make -j5 -s -w -C $DEV_ROOT/
"command! -nargs=* Mk silent make -w -C <args> | cwindow 3

vmap cc :s/^/\/\/ /<CR>
vmap cu :s/\v^(\/\/\|#)//<CR>

" Use blackhole register to paste (keeps yanked text)
vmap p "_dP


""""""""""""""""""""COLORS""""""""""""""""""""""
"set gfn=Monospace\ 8
set guifont=Bitstream\ Vera\ Sans\ Mono\ 8

syntax enable
set enc=utf-8

if &term =~ '256color'
  " disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
  set t_Co=256
endif

"colorscheme hybrid_reverse
"colorscheme hybrid_material
if has("gui_running")
  set background=dark
  colorscheme desert
else
  set term=screen-256color
  let $TERM='screen-256color'
  colorscheme desert-warm-256
  set background=dark
  let g:vitality_tmux_can_focus = 1
  colorscheme PaperColor
  let g:PaperColor_Theme_Options = {
    \   'theme': {
    \     'default': {
    \       'allow_bold': 1,
    \     }
    \   }
    \ }
  if &term =~ '^screen'
    " tmux will send xterm-style keys when its xterm-keys option is on
    execute "set <xHome>=\e[1;*H"
    execute "set <Home>=\e[1;*H"
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
  endif
endif

" On colorscheme change force reset of cursorline
augroup CustomCursorLine
au!
au ColorScheme * :hi! CursorLine  ctermbg=253
augroup END

"""""""""""""""""""" TAGS""""""""""""""""""""""
"set tags=$DEV_ROOT/linux_toolchain/linux/tags
"set tags+=$DEV_ROOT/runtime/tags
"set tags+=$DEV_ROOT/libraries/rpc-firmwares/tags

" recurse up to tags with limit $DEV_ROOT/work
set tags=./.tags;,.tags;,tags;$DEV_ROOT/work
nnoremap <leader>t :tag <c-r><c-w><cr>
"C-t to go back

"""""""""""""""""""" AUTOTAGS"""""""""""""""""""""
let g:autotagTagsFile=".tags"
let g:autotagStopAt="$DEV_ROOT/work"

"""""""""""""""""""" CSCOPE""""""""""""""""""""""
"set cscopequickfix=s-,c-,d-,i-,t-,e-
"
"if has("cscope")
" set csto=1
" "set csverb
" set nocsverb
" set cspc=3
" silent cs add $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom/cscope.out
" silent cs add $DEV_ROOT/runtime/ethernet/cscope.out
" silent cs add $DEV_ROOT/libraries/rpc-firmwares/cscope.out
" " set nocst "default use tag shortcuts (C-])
"endif

" snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-tab>"
"let g:UltiSnipsEditSplit="vertical"

"""""""""""""""""" OmniCppCompletion""""""""""""""""""""

" Enable OmniCompletion
" http://vim.wikia.com/wiki/Omni_completion
filetype plugin on
set omnifunc=syntaxcomplete#Complete
au BufNewFile,BufRead,BufEnter *.c,*.h,*.cpp,*.hpp set omnifunc=omni#cpp#complete#Main
" enable global scope search
let OmniCpp_GlobalScopeSearch = 1
" show function parameters
let OmniCpp_ShowPrototypeInAbbr = 1
" show access information in pop-up menu
let OmniCpp_ShowAccess = 1
" auto complete after '.'
let OmniCpp_MayCompleteDot = 1
" auto complete after '->'
let OmniCpp_MayCompleteArrow = 1
" auto complete after '::'
let OmniCpp_MayCompleteScope = 1
" select first item in pop-up menu
let OmniCpp_SelectFirstItem = 0
let OmniCpp_NamespaceSearch = 1
let OmniCpp_DisplayMode         = 1
let OmniCpp_ShowScopeInAbbr     = 0 "do not show namespace in pop-up
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
set completeopt=menuone,menu
set complete-=i "remove include file search
set pumheight=20
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

"""""""""""""""""""" SUPERTAB""""""""""""""""""""""
" SuperTab option for context aware completion
" SuperTab completion fall-back 
"let g:SuperTabDefaultCompletionType='<c-x><c-u><c-p>'
let g:SuperTabLongestHighlight = 1  "preselect first entry
let g:SuperTabDefaultCompletionType = "context"
"au BufNewFile,BufRead,BufEnter *.c,*.h,*.cpp,*.hpp let g:SuperTabDefaultCompletionType = "<C-X><C-O>"

"let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']

"let g:SuperTabCompletionContexts = ['s:ContextText', 's:ContextDiscover']
"let g:SuperTabContextDiscoverDiscovery = ["&omnifunc:<c-x><c-u>", "&omnifunc:<c-x><c-o>"]

""""""""""""""""" Jedi completion"""""""""""""""""""
"let g:jedi#auto_initialization = 1
"let g:jedi#auto_vim_configuration = 1

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
nnoremap vb <ESC> :vert belowright sbNext<CR> :set columns=210 <CR> :cclose <CR> :wincmd =<CR>
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
nnoremap <leader>g :%diffget<CR>

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

let g:linediff_first_buffer_command  = 'new'
let g:linediff_further_buffer_command = 'vertical new'

""""""""""""""""""""" TAB"""""""""""""""""""""
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_show=2

let g:BufTabLineCurrent="TabLineSel"  "current window
let g:BufTabLineActive="TabLine" "other window

""""""""""""""""""""" Powerline"""""""""""""""""""""
"set rtp+=$HOME/softs/powerline/powerline/bindings/vim/
"set laststatus=2
"set t_Co=256
"
"let g:Powerline_symbols = 'fancy'
"set fillchars+=stl:\ ,stlnc:\

""""""""""""""""""""" Airline"""""""""""""""""""""
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:airline_symbols.crypt = '🔒'
let g:airline_symbols.whitespace = 'Ξ'
let g:airline_symbols.linenr = '¶'
set laststatus=2
set encoding=utf-8

let g:airline_theme='papercolor'
let g:airline_theme='dark'
"let g:airline_solarized_dark_text = 1
"let g:airline_solarized_normal_green = 1
"let g:airline_solarized_dark_inactive_border = 1
"let g:solarized_base16 = 1
"let g:airline_base16_improved_contrast = 1

""""""""""""""""""""" Ack"""""""""""""""""""""""""
" prefix with s: for local script-only functions / a: prefix for arguments
function! s:search(pattern)
  "echom "Command: " . a:pattern
  :execute 'Ack --cpp '. a:pattern.' $DEV_ROOT'
endfunction

"map <F3> :execute "noautocmd vimgrep /" .expand("<cword>") . "/j ../*/*.[ch]" <Bar> cw<CR>
map <F3> :execute "noautocmd Ggrep " .expand("<cword>") <Bar> cw<CR><CR>
command! -nargs=1 Search call s:search(<f-args>) | lwindow

""""""""""""""""""""" Bufferlist"""""""""""""""""""""""
map <silent> <C-b> :call BufferList()<CR>
let g:BufferListWidth = 30
let g:BufferListMaxWidth = 50

""""""""""""""""""""" CtrlP"""""""""""""""""""""""
let g:ctrlp_map = '<C-f>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_by_filename = 1
let g:ctrlp_max_files = 600
let g:ctrlp_max_depth = 20
let g:ctrlp_use_caching = 1
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'
"let g:ctrlp_lazy_update = 50
let g:ctrlp_switch_buffer = 'E'
let g:ctrlp_regexp = 0
let g:ctrlp_mruf_relative = 1
let g:ctrlp_types = ['mru', 'tag', 'fil', 'buf']
let g:ctrlp_extensions = ['mixed', 'tag']

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
  let g:ctrlp_user_command = 'ag %s -i
      \ --nocolor --nogroup --hidden
      \ --ignore .repo
      \ --ignore .git
      \ --ignore .svn
      \ --ignore .hg
      \ --ignore .DS_Store
      \ --ignore test
      \ --ignore golden
      \ --ignore "*tmp*"
      \ --ignore "**/*.pyc"
      \ --ignore "obj"
      \ -g ""'
endif

let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)|debug|obj|linux_x86$',
  \ 'file': '\v\.(exe|so|dll|bin|o|v|d|a|gold)$',
  \ }

"""""""""""""""""" ConqueGDB"""""""""""""""""
"let dev_root="$DEV_ROOT"
"let g:ConqueTerm_Color = 2         " 1: strip color after 200 lines, 2: always with color
"let g:ConqueTerm_CloseOnEnd = 1    " close conque when program ends running
"let g:ConqueTerm_StartMessages = 1 " display warning messages if conqueTerm is configured incorrectly
"
"let g:ConqueGdb_SaveHistory = 1
"let g:ConqueTerm_Color = 0
"let g:ConqueTerm_CloseOnEnd = 1
""let g:ConqueGdb_Leader = ','
"let g:ConqueTerm_ReadUnfocused = 1
"
"command! -nargs=*  Dc :ConqueGdbCommand <args>

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
nnoremap <C-h> :TagbarToggle <CR>
nnoremap <C-e> :chdir %:p:h <CR> :NERDTreeCWD <CR>
nnoremap <C-z> :NERDTreeToggle <CR>

" auto chdir
let g:NERDTreeMouseMode=3
let g:NERDTreeChDirMode=2
let g:NERDTreeWinSize=35
let g:NERDTreeWinPos="left"
let NERDTreeDirArrows = 1

""""""""""""""""" DoxyToolkit""""""""""""""""
let g:DoxygenToolkit_compactDoc = "yes"
let g:C_UseTool_doxygen = 'yes'

""""""""""" SESSIONS (save and restore)""""""""""""""""
set sessionoptions=blank,buffers ",folds,help,options,localoptions,winsize,tabpages
set sessionoptions+=unix,slash,tabpages,winsize

noremap ss :mksession! ~/.vim/sessions/
noremap rs :so ~/.vim/sessions/



syntax enable
