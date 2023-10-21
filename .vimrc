" ---------------------Content
" general_settings
" config_buffer
" config_motion
" config_plugins
" config_nerdtree
" config_plugin_settings
"_______________________________________________________________________________
set nocompatible              " be iMproved, required
filetype on

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
set ignorecase
set smartcase
set incsearch
set formatoptions-=cro " Stop auto commenting newlines
set undofile
set relativenumber
autocmd FileType yaml set colorcolumn
autocmd FileType yml set colorcolumn
autocmd FileType python set colorcolumn

set wildignore+=*/tmp/*
set wildignore+=*/node_modules/*
set wildignore+=*/bower_components/*
set wildignore+=*/build/*
set wildignore+=*.swp
set wildignore+=*.swp
set wildignore+=*/venv/*

" Toggle Relative Numberline
nnoremap <leader>r :setlocal relativenumber!<CR>

" Map enter key to esc
inoremap jk <Esc>

" Reload and edit vim config file
nnoremap <Leader>ve :e $MYVIMRC<CR>
nnoremap <Leader>vr :source $MYVIMRC<CR>
"-------------------------------------------------------------------------------
"                                                                config_buffer
" Mappings to access buffers (don't use "\p" because a
" delay before pressing "p" would accidentally paste).
" \l       : list buffers
" \b \f \g : go back/forward/last-used
nnoremap <Leader>b :bp<CR>
nnoremap <Leader>n :bn<CR>
nnoremap <Leader>e :Bd<CR>

"-------------------------------------------------------------------------------
"                                                                config_motion
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
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-projectionist'
" Plugin 'cukejianya/onedark.vim'
" Plugin 'joshdick/onedark.vim'
" Plugin 'vim-airline/vim-airline'
Plugin 'jiangmiao/auto-pairs'
Plugin 'ap/vim-css-color'
" Plugin 'vim-airline/vim-airline-themes'
Plugin 'ryanoasis/vim-devicons'
Plugin 'mattn/emmet-vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'kshenoy/vim-signature'
" Plugin 'quramy/tsuquyomi'
Plugin 'pantharshit00/vim-prisma'
Plugin 'jparise/vim-graphql'
Plugin 'moll/vim-bbye'
Plugin 'vim-test/vim-test'
Plugin 'junegunn/goyo.vim'
" Plugin 'uiiaoo/java-syntax.vim'
Plugin 'sheerun/vim-polyglot'
" The foignorellowing are examples of different formats supported.
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

" let g:javascript_plugin_jsdoc = 1

" syntax enable
" if (has("nvim"))
      " let $NVIM_TUI_ENABLE_TRUE_COLOR=1
" endif
" if (has("termguicolors"))
      " set termguicolors
" endif
" colorscheme onedark
let g:onedark_terminal_italics=1

" " Enable mysql cli editting mode to use syntax highlighting
" augroup sql
  " autocmd!
  " autocmd BufNew,BufEnter /**/sql[\w]* setlocal filetype=sql
" augroup END
"______________________________________________________________________________config_plugin_settings
" NerdCommenter Setup
let g:NERDSpaceDelims = 1

" Airline Setup
" let g:airline_theme='angr'
" let g:airline#extensions#tabline#enabled = 1
" let g:airline#extensions#gutentags#enabled = 1

" Emmet Setup
let g:user_emmet_leader_key=','
let g:user_emmet_mode='nv'

" Fugitive Setup
let g:fugitive_pty = 0

" Vim Test Setup
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tt :TestFile<CR>"
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> gT :A<CR>

" Vim Projectionist Setup
let g:projectionist_heuristics = {
      \   "pom.xml": {
      \     "src/main/java/*.java": {
      \       "type": "source",
      \       "alternate": "src/test/java/{dirname}/{basename}Test.java"
      \     },
      \     "src/test/java/*Test.java": {
      \       "type": "test",
      \       "alternate": "src/main/java/{}.java"
      \     },
      \   },
      \ }
"_______________________________________________________________________________
