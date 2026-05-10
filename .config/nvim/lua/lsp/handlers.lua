local M = {}

function M.on_attach(client, buffer)
  client.server_capabilities.semanticTokensProvider = nil
  require("lsp.keymaps").setup(buffer)
end

function M.capabilities()
  require("cmp_nvim_lsp").default_capabilities()
end

return M
