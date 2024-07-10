set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
set termguicolors

lua <<EOF
  -- disable netrw at the very start of your init.lua
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  require("config.lazy")
  vim.keymap.set('n', '<leader>vr', ':source ~/.config/nvim/init.vim<CR>')
EOF

