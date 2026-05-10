local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Autosave Session during exit
augroup("__autosave__", { clear = true })
autocmd("VimLeavePre", {
  group = "__autosave__",
  command = ":mksession!",
})

local answer = vim.fn.confirm("Open saved session?", "&Yes\n&No", 2)

if answer == 1 then
  vim.cmd("source Session.vim")
end
