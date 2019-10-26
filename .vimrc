set nocompatible              " be iMproved, required
filetype off                  " required

" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete
set wildmenu

" Don’t add empty newlines at the end of files
set binary
set noeol

" General Settings
set mouse=i
set number
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

set wildignore+=*/tmp/*
set wildignore+=*/node_modules/*
set wildignore+=*/bower_components/*
set wildignore+=*/build/*
set wildignore+=*.swp

" Automatically Close Brackets|Paranthesis|Quotes
inoremap " ""<left>
inoremap ' ''<left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>O

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
Plugin 'ap/vim-css-color'
Plugin 'scrooloose/nerdtree'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'ctrlpvim/ctrlp.vim' " Finds files with ctrl-p
Plugin 'wincent/command-t'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'sheerun/vim-polyglot'
Plugin 'ryanoasis/vim-devicons'
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

" Syntastic Setup
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Syntastic HTML Setup
let g:syntastic_html_tidy_blocklevel_tags = ['svg', 'g', 'circle']
let g:syntastic_html_tidy_inline_tags = ['svg', 'g', 'circle'] 
let g:syntastic_html_tidy_ignore_errors = ["trimming empty <i>"] 

" NERDtree Setup
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
map <Bar> :NERDTreeToggle<CR>
let NERDTreeRespectWildIgnore=1
" Next 4 lines is to fix spacing btw icon and arrows
let g:WebDevIconsNerdTreeBeforeGlyphPadding = ''
let g:WebDevIconsUnicodeDecorateFolderNodes = v:true
let g:NERDTreeDirArrowExpandable = "\u00a0"
let g:NERDTreeDirArrowCollapsible = "\u00a0"

" Airline Setup
let g:airline_theme='angr'
let g:airline#extensions#tabline#enabled = 1

" ctrl-p 
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'