set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
lua <<EOF
  require('plugins')
  require('lsp')
EOF
