set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
lua <<EOF
  require('plugins')
  require('lsp')
  require('tree')
  require('telescope_conf')
  require('debugger')
  require('theme')
  require('statusline')
  require('git')
  require('treesitter_setup')
  require('indent_blankline')
  require('formatter_conf')

  require('git-conflict').setup({})

  vim.keymap.set('n', '<leader>vr', ':source ~/.config/nvim/init.vim<CR>')
EOF
