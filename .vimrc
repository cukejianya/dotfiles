" ---------------------Content
" general_settings
" config_plugins
" config_syntastic
" config_nerdtree
"_______________________________________________________________________________
set nocompatible              " be iMproved, required
filetype off                  " required

" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete
set wildmenu

" Don’t add empty newlines at the end of files
" set binary
" set noeol

"-------------------------------------------------------------------------------
"                                                             general_settings
set number
set relativenumber
set encoding=UTF-8
set wrap
set textwidth=79
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent
set backspace=2
set list
set hidden
set foldmethod=indent
set nofoldenable
set colorcolumn=81
set hlsearch
set cursorline
set splitbelow
set splitright

set wildignore+=*/tmp/*
set wildignore+=*/node_modules/*
set wildignore+=*/bower_components/*
set wildignore+=*/build/*
set wildignore+=*.swp

" Toggle Relative Numberline
nnoremap <leader>n :setlocal relativenumber!<CR>

" Map enter key to esc
inoremap jk <Esc>

" Automatically Close Brackets|Paranthesis|Quotes
" if you don't want the default use clrl + v before type key
inoremap " ""<left>
inoremap ' ''<left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>O

" Mappings to access buffers (don't use "\p" because a
" delay before pressing "p" would accidentally paste).
" \l       : list buffers
" \b \f \g : go back/forward/last-used
" \1 \2 \3 : go to buffer 1/2/3 etc
nnoremap <Leader>l :ls<CR>
nnoremap <Leader>b :bp<CR>
nnoremap <Leader>f :bn<CR>
nnoremap <Leader>e :bd<CR>
nnoremap <Leader>g :e#<CR>
nnoremap <Leader>1 :bfirst<CR>
nnoremap <Leader>2 :bfirst<CR>:1bn<CR>
nnoremap <Leader>3 :bfirst<CR>:2bn<CR>
nnoremap <Leader>4 :bfirst<CR>:3bn<CR>
nnoremap <Leader>5 :bfirst<CR>:4bn<CR>
nnoremap <Leader>6 :bfirst<CR>:5bn<CR>
nnoremap <Leader>7 :bfirst<CR>:6bn<CR>
nnoremap <Leader>8 :bfirst<CR>:7bn<CR>
nnoremap <Leader>9 :bfirst<CR>:8bn<CR>
nnoremap <Leader>0 :bfirst<CR>:9bn<CR>

" Disable Arrow Keys scrolling
map <up>    <nop>
map <down>  <nop>
map <left>  <nop>
map <right> <nop>

" Map Split Navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"------------------------------------------------------------------------------
"                                                             config_plugins
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
" Custom Plugins
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-surround'
" Plugin 'valloric/youcompleteme'
Plugin 'joshdick/onedark.vim'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
Plugin 'airblade/vim-gitgutter' " Shows git diff in the 'gutter'
Plugin 'vim-airline/vim-airline'
Plugin 'jiangmiao/auto-pairs'
Plugin 'ap/vim-css-color'
Plugin 'scrooloose/nerdtree'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'ctrlpvim/ctrlp.vim' " Finds files with ctrl-p
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'sheerun/vim-polyglot' " Syntax Highlighter Bundle
Plugin 'ryanoasis/vim-devicons'
Plugin 'rking/ag.vim'
" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
Plugin 'L9'
Plugin 'ZoomWin'

" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" i.e. Plugin 'file:///home/gmarik/path/to/plugin'

" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}

" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

let g:javascript_plugin_jsdoc = 1

syntax enable
set background=dark
colorscheme onedark

" Enable mysql cli editting mode to use syntax highlighting
augroup sql
  autocmd!
  autocmd BufNew,BufEnter /**/sql[\w]* setlocal filetype=sql
augroup END

"_______________________________________________________________________________
"                                                             config_syntastic 
" Syntastic Setup
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 2
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Syntastic HTML Setup
let g:syntastic_html_tidy_blocklevel_tags = ['svg', 'g', 'circle']
let g:syntastic_html_tidy_inline_tags = ['svg', 'g', 'circle'] 
let g:syntastic_html_tidy_ignore_errors = ["trimming empty <i>"] 

" Syntastic Setup
let g:syntastic_php_checkers = ['php', 'phpcs']
let g:syntastic_php_phpcs_quiet_messages = { '!level': 'error' }
let g:syntastic_php_phpcs_args='--standard=~/.phpcs.xml'

"_______________________________________________________________________________
"                                                             config_nerdtree
" NERDtree Setup
let g:NERDTreeQuitOnOpen=0
let NERDTreeShowHidden=1
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
map <Leader>k :NERDTreeToggle<CR>
nmap <Leader>y :NERDTreeFind<CR>
let NERDTreeRespectWildIgnore=1
" Next 4 lines is to fix spacing btw icon and arrows
let g:WebDevIconsNerdTreeBeforeGlyphPadding = ''
let g:WebDevIconsUnicodeDecorateFolderNodes = v:true
let g:NERDTreeDirArrowExpandable = "\u00a0"
let g:NERDTreeDirArrowCollapsible = "\u00a0"

" Airline Setup
let g:airline_theme='angr'
let g:airline#extensions#tabline#enabled = 1

" Ctrl-P Setup
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
