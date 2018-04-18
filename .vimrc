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
Plug 'https://github.com/kristijanhusak/vim-hybrid-material.git'
Plug 'https://github.com/altercation/vim-colors-solarized.git'

Plug 'https://github.com/vim-scripts/perl-support.vim.git'
Plug 'https://github.com/vim-scripts/ctags.vim.git'
Plug 'https://github.com/chazy/cscope_maps.git'
Plug 'https://github.com/scrooloose/nerdtree.git'
"Plug 'https://github.com/scrooloose/nerdcommenter.git'
Plug 'https://github.com/ap/vim-buftabline.git'
Plug 'https://github.com/vim-scripts/cpp.vim.git'
Plug 'https://github.com/vim-scripts/python.vim.git'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/vim-airline/vim-airline.git'
Plug 'https://github.com/vim-airline/vim-airline-themes.git'
Plug 'https://github.com/majutsushi/tagbar.git'
Plug 'https://github.com/ctrlpvim/ctrlp.vim'
Plug 'jacquesbh/vim-showmarks'
"" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'https://github.com/ervandew/supertab.git'
Plug 'https://github.com/scrooloose/syntastic.git'
Plug 'https://github.com/vim-scripts/BufOnly.vim.git'
Plug 'https://github.com/vim-scripts/bufferlist.vim.git'
Plug 'mileszs/ack.vim'
"Plug 'https://github.com/vim-scripts/Conque-GDB.git'
"Plug 'https://github.com/Valloric/YouCompleteMe.git'
Plug 'https://github.com/bogado/file-line.git'
Plug 'https://github.com/chrisbra/vim-autosave.git'
Plug 'https://github.com/vim-scripts/DoxygenToolkit.vim.git'

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
"set expandtab
set bs=2
set ts=4
set shiftwidth=4
set number
set list
set listchars=tab:>-,trail:.,extends:>
set columns=200
set cursorline
set autoread
set autowrite
set wildmenu
"set wildmode=list:longest
set wildmode=full
set ruler
set wrap
"set iskeyword-=:
set colorcolumn=80

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
set wildignore+=*/build/**
set wildignore+=*/obj/**
set wildignore+=*/stubobj/**
set wildignore+=*/debug*/**
set wildignore+=*/.git/**
set wildignore+=*/linux_x86/**
set wildignore+=*.so,*.swp,*.zip,*.o,*.l,*.y,*.a,*.exe,*.gold

set path+=$DEV_ROOT/**

autocmd! bufwritepost .vimrc source %
" quickwindow
autocmd FileType qf wincmd J

autocmd FocusLost,BufLeave * silent! :wa!

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
autocmd BufEnter * silent! :DoShowMarks!

map <F1> :tn <CR>

map <F5> :source $HOME/.vimrc <CR>
"map <F6> :! $HOME/utils/update_ctags.sh & <CR>

noremap <C-M> :set columns=235 <CR> :cclose <CR> :wincmd =<CR>
noremap <F11> :set columns=310 <CR>
nnoremap <C-o> :BufOnly <CR>
noremap <F4> :bp<CR>:bd # <CR>
noremap <C-s-t> :vs<bar>:b#<CR>
noremap <F8> :vertical wincmd f<CR>

" open header/cpp files
noremap ,h :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow
noremap <F9> :wa <CR> :make -j5 -s -w -C $DEV_ROOT/
"command! -nargs=* Mk silent make -w -C <args> | cwindow 3

vmap cc :s/^/\/\/ /<CR>
vmap cu :s/\v^(\/\/\|#)//<CR>

" Use blackhole register to paste (keeps yanked text)
vmap p "_dP

""""""""""""""""""""COLORS""""""""""""""""""""""
set background=dark
"colorscheme hybrid_reverse
colorscheme desert

"hi DiffText term=reverse cterm=bold ctermbg=12 gui=bold guifg=White guibg=#a02222
"hi DiffChange term=reverse cterm=bold ctermbg=12 guifg=White guibg=#173117
""DiffAdd, DiffChange, DiffDelete
hi StatusLine guibg=#8c8e91 guifg=#44484f gui=bold
hi StatusLineNC guibg=#8c8e91 guifg=#44484f gui=bold
"hi TabLineFill guibg=#8c9e91 guifg=#14181f gui=bold
"hi TabLineSel guibg=#6c6e61 guifg=#14181f gui=bold
"hi TabLine guibg=#8c9e91 guifg=#14181f gui=bold
"hi CursorLine cterm=bold guifg=NONE guibg=#525252

"""""""""""""""""""" TAGS""""""""""""""""""""""
set tags=$DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom/tags,$DEV_ROOT/runtime/tags,$DEV_ROOT/libraries/rpc-firmwares/tags


function! GoToTag(tagWord)
	let l:tagfile = &tags
	execute 'set tags=' . l:tagfile
	execute 'tjump ' . a:tagWord
endfunction

function! Callers(tagWord)
	let l:tagfile = &tags
	execute 'set tags=' . l:tagfile
	execute 'cs find c ' . a:tagWord
endfunction

function! Called(tagWord)
	let l:tagfile = &tags
	execute 'set tags=' . l:tagfile
	execute 'cs find d ' . a:tagWord
endfunction

map <C-f> "zyiw:exe "call GoToTag(@z)"<CR>
map <C-g> "zyiw:exe "call Callers(@z)"<CR>
map <C-d> "zyiw:exe "call Called(@z)"<CR>

"""""""""""""""""""" CSCOPE""""""""""""""""""""""
set cscopequickfix=s-,c-,d-,i-,t-,e-

if has("cscope")
 set csto=1
 set cst
 "set csverb
 set nocsverb
 set cspc=3
 silent cs add $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom/cscope.out
 silent cs add $DEV_ROOT/runtime/ethernet/cscope.out
 silent cs add $DEV_ROOT/libraries/rpc-firmwares/cscope.out
" command -nargs=0 Cscope cs add $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom/cscope.out
 nmap l :cs find c <C-R>=expand("<cword>")<CR><CR>
 nmap L :cs find s <C-R>=expand("<cword>")<CR><CR>
 set nocst "default use tag shortcuts (C-])
endif

" snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-tab>"
"let g:UltiSnipsEditSplit="vertical"

"""""""""""""""""""" AutoSave""""""""""""""""""""""
let g:autosave_extensions = '.bkp'
let g:autosave_backup='/work1/tcostis/tmp/backup/vim/'
let g:autosave_timer=300
"
"""""""""""""""""""" CLANG_COMPLETE""""""""""""""""""""""
"set omnifunc=
"set completefunc=
"let g:clang_complete_loaded = 1
""let g:clang_debug = 1
"" Disable auto popup, use <Tab> to autocomplete
"let g:clang_complete_auto = 1
"" Show clang errors in the quickfix window
"let g:clang_complete_copen = 1
"let g:clang_use_library = 1
"let g:clang_library_path='/local_home/thomas/soft/local/usr/lib64/llvm/'
"let g:clang_trailing_placeholder = 1
"let g:clang_close_preview = 1
"let g:clang_auto_select = 1
"set conceallevel=2
"set concealcursor=vin
"" Don't use snippets for function completion
""let g:clang_conceal_snippets=1
""let g:clang_snippets = 1
""let g:clang_snippets_engine = 'clang_complete'
"" let g:clang_snippets_engine = 'ultisnips'
"let g:clang_complete_patterns = 1
"let g:clang_complete_optional_args_in_snippets = 1
"" Complete options (disable preview scratch window, longest removed to always show menu)
"set completeopt=menu,menuone,preview
"
"" Limit popup menu height
"set pumheight=20
"
""let g:clang_jumpto_declaration_key = ',d'
"let g:clang_user_options = '-std=c++11'
""set complete-=i " disable completion from include files
"

"""""""""""""""""" OmniCppCompletion""""""""""""""""""""

" Enable OmniCompletion
" http://vim.wikia.com/wiki/Omni_completion
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Configure menu behavior
" http://vim.wikia.com/wiki/VimTip1386
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

" Use Ctrl+Space for omni-completion
" http://stackoverflow.com/questions/510503/ctrlspace-for-omni-and-keyword-completion-in-vim
inoremap <expr> <C-Space> pumvisible() \|\| &omnifunc == '' ?
  \ "\<lt>C-n>" :
  \ "\<lt>C-x>\<lt>C-o><c-r>=pumvisible() ?" .
  \ "\"\\<lt>c-n>\\<lt>c-p>\\<lt>c-n>\" :" .
  \ "\" \\<lt>bs>\\<lt>C-n>\"\<CR>"
imap <C-@> <C-Space>

" Popup menu hightLight Group
"highlight Pmenu ctermbg=13 guibg=LightGray
"highlight PmenuSel ctermbg=7 guibg=DarkBlue guifg=White
"highlight PmenuSbar ctermbg=7 guibg=DarkGray
"highlight PmenuThumb guibg=Black

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
let OmniCpp_MayCompleteScope = 0
" select first item in pop-up menu
let OmniCpp_SelectFirstItem = 1
let OmniCpp_NamespaceSearch = 1
let OmniCpp_DisplayMode         = 1
let OmniCpp_ShowScopeInAbbr     = 0 "do not show namespace in pop-up
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
set completeopt=menuone,menu,longest

"""""""""""""""""""" SUPERTAB""""""""""""""""""""""
" SuperTab option for context aware completion
" SuperTab completion fall-back 
"let g:SuperTabDefaultCompletionType='<c-x><c-u><c-p>'
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']
function! MyTagContext()
  if filereadable(expand('%:p:h') . '/tags')
    return "\<c-x>\<c-]>"
  endif
  " no return will result in the evaluation of the next
  " configured context
endfunction
let g:SuperTabCompletionContexts = ['MyTagContext', 's:ContextText', 's:ContextDiscover']
let g:SuperTabContextDiscoverDiscovery = ["&completefunc:<c-x><c-u>", "&omnifunc:<c-x><c-o>"]

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
nnoremap ,g :%diffget<CR>

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

let g:BufTabLineCurrent="TabLineSel"  "current window
let g:BufTabLineActive="TabLine" "other window

""""""""""""""""""""" Airline"""""""""""""""""""""
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline#extensions#ctrlp#show_adjacent_modes = 1
let g:airline#extensions#syntastic#enabled = 1
"let g:airline_theme='solarized'
"let g:airline_solarized_bg='light'
let g:airline_theme='lucius' "cool
" avoid issues with buffer changes
let g:airline#extensions#tagbar#enabled = 0

""""""""""""""""""""" Ack"""""""""""""""""""""""""
" prefix with s: for local script-only functions / a: prefix for arguments
function! s:search(pattern)
  "echom "Command: " . a:pattern
  :execute 'Ack --cpp '. a:pattern.' $DEV_ROOT'
endfunction

map <F3> :execute "noautocmd vimgrep /" .expand("<cword>") . "/j ../*/*.[ch]" <Bar> cw<CR>
"map <F3> :execute "noautocmd Ack /" ."--cpp" .expand("<cword>") . "$DEV_ROOT" <Bar> cw <CR>
"map <F3> :execute 'Ack --ignore linux_x86 --cpp <cword> $DEV_ROOT' <CR>
command! -nargs=1 Search call s:search(<f-args>) | lwindow

""""""""""""""""""""" Bufferlist"""""""""""""""""""""""
map <silent> <C-b> :call BufferList()<CR>
let g:BufferListWidth = 30
let g:BufferListMaxWidth = 50

""""""""""""""""""""" CtrlP"""""""""""""""""""""""
let g:ctrlp_map = '<C-c>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_by_filename = 1
let g:ctrlp_max_files = 600
let g:ctrlp_max_depth = 20
let g:ctrlp_use_caching = 1
let g:ctrlp_clear_cache_on_exit = 1
let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'
"let g:ctrlp_lazy_update = 50
let g:ctrlp_switch_buffer = 'E'
let g:ctrlp_regexp = 0
let g:ctrlp_mruf_relative = 1
let g:ctrlp_types = ['mixed', 'tag']
let g:ctrlp_extensions = ['mixed', 'tags']

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

""""""""""""""""" Python"""""""""""""""""
"let g:pymode_python = 'python3'
"autocmd filetype python set expandtab

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

""""""""""""""""" DoxyToolkit""""""""""""""""
let g:DoxygenToolkit_compactDoc = "yes"
let g:C_UseTool_doxygen = 'yes'

""""""""""" SESSIONS (save and restore)""""""""""""""""
set sessionoptions=blank,buffers ",folds,help,options,localoptions,winsize,tabpages
set sessionoptions+=unix,slash,tabpages,winsize

noremap ss :mksession! ~/.vim/sessions/
noremap rs :so ~/.vim/sessions/

set gfn=Monospace\ Regular\ 8
syntax on
