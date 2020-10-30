" ---------------------Content
" general_settings
" config_buffer
" config_motion
" config_plugins
" config_syntastic
" config_nerdtree
" config_gutentags
" config_plugin_settings
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
set wildignore+=*.swp

" Toggle Relative Numberline
nnoremap <leader>n :setlocal relativenumber!<CR>

" Map enter key to esc
inoremap jk <Esc>

"-------------------------------------------------------------------------------
"                                                                config_buffer
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
Plugin 'mileszs/ack.vim'
Plugin 'mattn/emmet-vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'ludovicchabant/vim-gutentags'
Plugin 'kshenoy/vim-signature'
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

" Syntastic PHP Setup
let g:syntastic_php_checkers = ['php', 'phpcs']
let g:syntastic_php_phpcs_quiet_messages = { '!level': 'error' }
let g:syntastic_php_phpcs_args='--standard=~/.phpcs.xml'

" Syntastic Typescript Setup
let g:syntastic_typescript_checkers = ['tslint']
let g:syntastic_typescript_tslint_args = "--config ~/Crowdskout/helm-front/tslint.json"
"_______________________________________________________________________________
"                                                               config_nerdtree
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
" Enable line numbers
let NERDTreeShowLineNumbers=1
" Make sure relative line numbers are used
autocmd FileType nerdtree setlocal relativenumber
"_______________________________________________________________________________
"                                                               config_gutentags
" Gutentags Setup
" let g:gutentags_add_default_project_roots = 0
let g:gutentags_project_root = ['package.json', '.git']
let g:gutentags_cache_dir = expand('~/.cache/vim/ctags/')

" Running automatically
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
" let g:gutentags_generate_on_empty_buffer = 0

" " Generate more info tags
" " a: Access (or export) of class members
" " i: Inheritance information
" " l: Language of input file containing tag
" " m: Implementation information
" " n: Line number of tag definition
" " s: Signature of routine (e.g. prototype or parameter list)
" let g:gutentags_ctags_extra_args = [
      " \ '--tag-relative=yes',
      " \ '--fields=+ailmnS',
      " \ ]
" " List of files ignoring
" let g:gutentags_ctags_exclude = [
      " \ '*.git', '*.svg', '*.hg',
      " \ '*/tests/*',
      " \ 'build',
      " \ 'dist',
      " \ '*sites/*/files/*',
      " \ 'bin',
      " \ 'node_modules',
      " \ 'bower_components',
      " \ 'cache',
      " \ 'compiled',
      " \ 'docs',
      " \ 'example',
      " \ 'bundle',
      " \ 'vendor',
      " \ '*.md',
      " \ '*-lock.json',
      " \ '*.lock',
      " \ '*bundle*.js',
      " \ '*build*.js',
      " \ '.*rc*',
      " \ '*.json',
      " \ '*.min.*',
      " \ '*.map',
      " \ '*.bak',
      " \ '*.zip',
      " \ '*.pyc',
      " \ '*.class',
      " \ '*.sln',
      " \ '*.Master',
      " \ '*.csproj',
      " \ '*.tmp',
      " \ '*.csproj.user',
      " \ '*.cache',
      " \ '*.pdb',
      " \ 'tags*',
      " \ 'cscope.*',
      " \ '*.css',
      " \ '*.less',
      " \ '*.scss',
      " \ '*.exe', '*.dll',
      " \ '*.mp3', '*.ogg', '*.flac',
      " \ '*.swp', '*.swo',
      " \ '*.bmp', '*.gif', '*.ico', '*.jpg', '*.png',
      " \ '*.rar', '*.zip', '*.tar', '*.tar.gz', '*.tar.xz', '*.tar.bz2',
      " \ '*.pdf', '*.doc', '*.docx', '*.ppt', '*.pptx',
      " \ ]
"_______________________________________________________________________________ "                                                         config_plugin_settings
" Ack Setup
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" NerdCommenter Setup
let g:NERDSpaceDelims = 1

" Airline Setup
let g:airline_theme='angr'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#gutentags#enabled = 1

" Ctrl-P Setup
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

" Emmet Setup
let g:user_emmet_leader_key=','
let g:user_emmet_mode='nv'

" Fugitive Setup
let g:fugitive_pty = 0
