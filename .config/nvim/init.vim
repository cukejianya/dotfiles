set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
lua <<EOF
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

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
