set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
set termguicolors

lua <<EOF
  -- disable netrw at the very start of your init.lua
  vim.g.loaded_netrw = 1
  require("config.lazy")
  vim.keymap.set('n', '<leader>vr', ':source ~/.config/nvim/init.vim<CR>')
  vim.keymap.set('n', '<leader>csv', 
  ":4d<CR>" ..
  ":1,2d<CR>" ..
  ":$d<CR>" ..
  ":%s/\\s*|\\s*/|/g<CR>" ..
  ":%s/^|//g<CR>" ..
  ":%s/|$//g<CR>" ..
  ":%s/|/,/g<CR>"
)

EOF
