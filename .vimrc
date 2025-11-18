" ---------------------Content
" general_settings
" config_buffer
" config_motion
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
set textwidth=79
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent
set backspace=2
set list
set hidden
" set foldmethod=indent
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
set nowrap

set wildignore+=*/tmp/*
set wildignore+=*/node_modules/*
set wildignore+=*/bower_components/*
set wildignore+=*/build/*
set wildignore+=*.swp
set wildignore+=*.swp
set wildignore+=*/venv/*

" Toggle Relative Numberline
nnoremap <leader>r :setlocal relativenumber!<CR>

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
