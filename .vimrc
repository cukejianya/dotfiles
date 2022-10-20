" ---------------------Content
" general_settings
" config_buffer
" config_motion
" config_plugins
" config_nerdtree
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
set ignorecase
set smartcase
set incsearch
set formatoptions-=cro " Stop auto commenting newlines
set undofile
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
nnoremap <leader>n :setlocal relativenumber!<CR>

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
nnoremap <Leader>f :bn<CR>
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
Plugin 'joshdick/onedark.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'jiangmiao/auto-pairs'
Plugin 'ap/vim-css-color'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'ryanoasis/vim-devicons'
Plugin 'mattn/emmet-vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'kshenoy/vim-signature'
Plugin 'neoclide/coc.nvim'
Plugin 'quramy/tsuquyomi'
Plugin 'pantharshit00/vim-prisma'
Plugin 'jparise/vim-graphql'
Plugin 'moll/vim-bbye'
Plugin 'kyazdani42/nvim-web-devicons' " optional, for file icons
Plugin 'kyazdani42/nvim-tree.lua'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
Plugin 'nvim-treesitter/nvim-treesitter'
Plugin 'vim-test/vim-test'
Plugin 'junegunn/goyo.vim'
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

let g:javascript_plugin_jsdoc = 1

syntax enable
set background=dark
colorscheme onedark

" " Enable mysql cli editting mode to use syntax highlighting
" augroup sql
  " autocmd!
  " autocmd BufNew,BufEnter /**/sql[\w]* setlocal filetype=sql
" augroup END
"______________________________________________________________________________config_plugin_settings
" NerdCommenter Setup
let g:NERDSpaceDelims = 1

" Airline Setup
let g:airline_theme='angr'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#gutentags#enabled = 1

" fzf Setup
nmap <silent> <C-p> :GFiles<CR> 
nmap <Leader>l :Buffers<CR>
nmap <Leader>o :GFiles?<CR>

" Emmet Setup
let g:user_emmet_leader_key=','
let g:user_emmet_mode='nv'

" Fugitive Setup
let g:fugitive_pty = 0

" CoC Setup
set nobackup
set nowritebackup
set updatetime=300

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

let g:coc_global_extensions = [
      \ 'coc-json', 
      \ 'coc-git',
      \ 'coc-java',
      \ 'coc-prettier',
      \ 'coc-sh',
      \ 'coc-sql',
      \ 'coc-diagnostic',
      \ 'coc-eslint',
      \ 'coc-tsserver'
\]
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nmap <leader>rn <Plug>(coc-rename)

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

" Vim Test Setup
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tt :TestFile<CR>"
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> gt :A<CR>

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
"                                                       config_nvimtree_settings
" Nvim Tree Setup
nnoremap <Leader>k :NvimTreeToggle<CR>
nnoremap <Leader>y :NvimTreeFindFile<CR>
lua << EOF
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = "u", action = "dir_up" },
      },
    },
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
  },
})
EOF
