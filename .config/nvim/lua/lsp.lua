vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

local capabilities = require('cmp_nvim_lsp').default_capabilities()
local builtin = require('telescope.builtin')

local common_on_attach = function(client, bufr)
  local bufopts = { noremap = true, silent = true, buffer = bufr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', "gr", builtin.lsp_references, bufopts)
  vim.keymap.set('n', "<leader>dff", function() builtin.diagnostics({ bufnr = 0 }) end, bufopts)
  vim.keymap.set('n', "<leader>df", vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', "<leader>rn", vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', "<leader>ac", vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', "<leader>=", vim.lsp.buf.format, bufopts)
end

-- Autoformat on save
-- vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]

-- Use telescope when looking up references
vim.lsp.handlers["textDocument/references"] = require("telescope.builtin").lsp_references

local lsp = {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

return lsp
