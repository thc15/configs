
set nocompatible              " be iMproved
filetype off                  " required!
let g:mapleader = ","


call plug#begin('~/.vim/plugged')
"Plug 'vim-scripts/desert-warm-256'
Plug 'https://github.com/altercation/solarized'
""Plug 'https://github.com/vim-scripts/AfterColors.vim.git'
"Plug 'https://github.com/NLKNguyen/papercolor-theme.git'
Plug 'https://github.com/vim-scripts/ctags.vim.git'
"Plug 'https://github.com/craigemery/vim-autotag.git'
"Plug 'https://github.com/majutsushi/tagbar.git' " error cant open file
"""Plug 'https://github.com/chazy/cscope_maps.git'
Plug 'https://github.com/scrooloose/nerdtree.git'
""Plug 'https://github.com/scrooloose/nerdcommenter.git'
Plug 'https://github.com/ap/vim-buftabline.git'
Plug 'https://github.com/vim-scripts/cpp.vim.git'
Plug 'https://github.com/vim-scripts/python.vim.git'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/jreybert/vimagit.git'
Plug 'https://github.com/kien/ctrlp.vim.git'
Plug 'jacquesbh/vim-showmarks'
Plug 'https://github.com/AndrewRadev/linediff.vim.git'
Plug 'https://github.com/machakann/vim-highlightedyank.git'
Plug 'https://github.com/tpope/vim-obsession.git'
""" Snippets
"Plug 'SirVer/ultisnips'
""Plug 'honza/vim-snippets'
Plug 'https://github.com/ervandew/supertab.git'
"Plug 'https://github.com/vim-scripts/BufOnly.vim.git'
"""Plug 'https://github.com/vim-scripts/bufferlist.vim.git'
Plug 'mileszs/ack.vim'
""Plug 'https://github.com/vim-scripts/Conque-GDB.git'
""Plug 'https://github.com/Valloric/YouCompleteMe.git'
Plug 'https://github.com/bogado/file-line.git'
Plug 'https://github.com/vim-scripts/DoxygenToolkit.vim.git'
Plug 'https://github.com/vim-scripts/OmniCppComplete.git'
Plug 'vim-scripts/Align'
Plug 'https://github.com/benmills/vimux.git'
Plug 'itchyny/lightline.vim'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""
set title
set hlsearch
set incsearch
"set smartcase   " do not use -> * fails to search with class delimiter ::
"set ignorecase
"set vb t_vb=
"set autochdir
"set nobackup
"set nowritebackup
set noswapfile
"" Don't redraw while executing macros (good performance config)
"set lazyredraw
""set noscrollbind
set scrolloff=5
set hidden
set switchbuf=usetab
"set autoindent
"set cino+=(0    " indent function args
"set expandtab
"set bs=2
"set ts=8
"set shiftwidth=0
"set number
"set list
"set listchars=tab:>-,trail:.,extends:>
"set autoread
"set autowrite
"set wildmenu
"set wildmode=list:longest
"set wildmode=list:full
"set ruler
"set wrap
"set cursorline
""set iskeyword-=:
"set columns=330
"set colorcolumn=80
""set undofile
set re=1
set timeoutlen=0
set laststatus=2
set encoding=utf-8

set clipboard=unnamed
set clipboard+=unnamedplus

set go+=a

" Disable bracketed mode
set t_BE=
set mouse=a

""""""""""""""""""""COLORS""""""""""""""""""""""
"set gfn=Monospace\ 8
set guifont=Bitstream\ Vera\ Sans\ Mono\ 8
"
set background=dark
"colorscheme solarized
colorscheme desert
"
"" On colorscheme change force reset of cursorline
augroup CustomCursorLine
   au!
   au ColorScheme * :hi! CursorLine ctermbg=333
   au ColorScheme * :hi! ColorColumn ctermbg=darkgray guibg=gray22
augroup END

" profile start profile.log
"profile func *
"profile file *
"""""""""""""""""""""MAPPING""""""""""""""""""""""
"
noremap <C-Left> :bp <CR>
noremap <C-Right> :bn <CR>

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



""""""""""""""""""""" TAB"""""""""""""""""""""
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_show=2

let g:BufTabLineCurrent="TabLineSel"  "current window
let g:BufTabLineActive="TabLine" "other window


""""""""""""""""""""" Ack"""""""""""""""""""""""""
" prefix with s: for local script-only functions / a: prefix for arguments
function! s:search(pattern)
	  "echom "Command: " . a:pattern
	    :execute 'Ack --cpp '. a:pattern.' $DEV_ROOT'
endfunction

map <F3> :execute "noautocmd vimgrep /" .expand("<cword>") . "/j**/*.[ch]" <Bar> cw<CR>
"map <F3> :execute "noautocmd Ggrep " .expand("<cword>") <Bar> cw<CR><CR>
command! -nargs=1 Search call s:search(<f-args>) | lwindow

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

let g:lightline = {
		\ 'colorscheme': 'wombat',
		\ 'enable': { 'tabline': 1 },
		\ 'active': {
		\   'left': [ [ 'mode', 'paste' ],
		\             [ 'gitbranch', 'readonly', 'filename', 'modified'] ]
		\ },
		\ 'component_function': {
		\   'gitbranch': 'fugitive#head'
		\ },
		\ }
set fillchars+=stl:\ ,stlnc:\


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
nnoremap <C-t> :TagbarToggle <CR>
nnoremap <C-e> :chdir %:p:h <CR> :NERDTreeCWD <CR>
nnoremap <C-d> :NERDTreeToggle <CR>

" auto chdir
let g:NERDTreeMouseMode=3
let g:NERDTreeChDirMode=2
let g:NERDTreeWinSize=35
let g:NERDTreeWinPos="left"
let NERDTreeDirArrows = 1
let NERDTreeQuitOnOpen = 3

"""""""""""""""""""" TAGS""""""""""""""""""""""
" recurse up to tags with limit $DEV_ROOT
set tags=./tags;,tags;,.tags;$DEV_ROOT
nnoremap <leader>t :tag <c-r><c-w><cr>
"C-t to go back

"""""""""""""""""""" AUTOTAGS"""""""""""""""""""""
let g:autotagTagsFile=".tags"
let g:autotagStopAt="$DEV_ROOT"

"""""""""""""""""""" CSCOPE""""""""""""""""""""""
"set cscopequickfix=s-,c-,d-,i-,t-,e-
"
"if has("cscope")
" set csto=1
" "set csverb
" set nocsverb
" set cspc=3
" silent cs add
" $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom/cscope.out
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
"set paste Do not set paste option
"let g:SuperTabDefaultCompletionType = "<c-n>"
"au BufNewFile,BufRead,BufEnter *.c,*.h,*.cpp,*.hpp let
"g:SuperTabDefaultCompletionType = "<C-X><C-O>"

"let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']

"let g:SuperTabCompletionContexts = ['s:ContextText', 's:ContextDiscover']
"let g:SuperTabContextDiscoverDiscovery = ["&omnifunc:<c-x><c-u>",
""&omnifunc:<c-x><c-o>"]

""""""""""""""""""""" SPLITS"""""""""""""""""""""""
set splitbelow
set splitright
"noremap sb :sbNext <CR>
nnoremap <F2> <ESC> :vert belowright sbNext<CR> :cclose <CR> :wincmd =<CR>
"nnoremap + :50winc +<CR>
"nnoremap - :30winc -<CR>

autocmd VimResized * exe "normal \<c-w>="

" Keep search matches in the middle of the window.
"nnoremap n nzzzv
"nnoremap N Nzzzv

""""""""""""""""" DoxyToolkit""""""""""""""""
let g:DoxygenToolkit_compactDoc = "yes"
let g:C_UseTool_doxygen = 'yes'

""""""""""" SESSIONS (save and restore)""""""""""""""""
set sessionoptions=blank,buffers
",folds,help,options,localoptions,winsize,tabpages
set sessionoptions+=unix,slash,tabpages,winsize

noremap ss :mksession! ~/.vim/sessions/
noremap rs :so ~/.vim/sessions/

set enc=utf-8
syntax enable
