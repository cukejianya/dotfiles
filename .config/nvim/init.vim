set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
set termguicolors

lua <<EOF
  -- disable netrw at the very start of your init.lua
  vim.g.loaded_netrw = 1
  require("config.lazy")
  
  vim.o.foldcolumn = '0' -- '0' is not bad
  vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
  vim.o.foldlevelstart = 99
  vim.o.foldenable = true
  vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

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

    local augroup = vim.api.nvim_create_augroup
    local autocmd = vim.api.nvim_create_autocmd
    augroup("__autosave__", { clear = true })
    autocmd("VimLeavePre", {
      group = "__autosave__",
      command = ":mksession!",
    })

    local answer = vim.fn.confirm( "Open saved session?",  "&Yes\n&No",    2)

if answer == 1 then
  vim.cmd("source Session.vim")
end

EOF
