local M = {}

function M.setup(bufr)
  local builtin = require("telescope.builtin")
  local bufopts = { noremap = true, silent = true, buffer = bufr }
  local map = vim.keymap.set

  map("n", "K", vim.lsp.buf.hover, bufopts)
  map("n", "gd", vim.lsp.buf.definition, bufopts)
  map("n", "gt", function()
    vim.cmd(":A")
  end, bufopts)
  map("n", "gi", vim.lsp.buf.implementation, bufopts)
  map("n", "gr", builtin.lsp_references, bufopts)
  map("n", "<leader>dff", function()
    builtin.diagnostics({ bufnr = 0 })
  end, bufopts)
  map("n", "<leader>df", vim.diagnostic.goto_next, bufopts)
  map("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
  map("n", "<leader>ac", vim.lsp.buf.code_action, bufopts)
  map("n", "<leader>=", vim.lsp.buf.format, bufopts)
end

return M
