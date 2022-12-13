set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
lua <<EOF
  require('plugins')
  require('lsp')
  require('tree')

  vim.keymap.set('n', '<leader>vr', ':source ~/.config/nvim/init.vim<CR>')
EOF
