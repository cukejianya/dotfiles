local lsp_servers = {
  "bashls",
  "cssls",
  "jsonls",
  "lua_ls",
  "marksman",
  "sqlls",
  "lemminx",
  "yamlls",
  "pyright",
  "arduino_language_server",
}

local lsp = vim.lsp
local handlers = require("lsp.handlers")
local lsp_conf = {
  on_attach = handlers.on_attach,
  capabilities = handlers.capabilities(),
}

for _, server in ipairs(lsp_servers) do
  lsp.config(server, lsp_conf)
end

lsp.enable(lsp_servers)

lsp.config("ltex", {
  on_attach = function(client, buffer)
    require("ltex_extra").setup({})
    handlers.on_attach(client, buffer)
  end,
  capabilities = handlers.capabilities(),
})

vim.lsp.config("vtsls", {
  on_attach = handlers.on_attach,
  capabilities = handlers.capabilities(),
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            languages = { "vue" },
            configNamespace = "typescript",
            location = vim.fn.stdpath("data")
              .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
          },
        },
      },
    },
  },
})

vim.lsp.config("vue_ls", {
  on_init = function(client)
    client.handlers["tsserver/request"] = function(_, result, context)
      local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
      if #clients == 0 then
        vim.notify("Could not found `vtsls` lsp client, vue_lsp would not work without it.", vim.log.levels.ERROR)
        return
      end
      local ts_client = clients[1]
      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        title = "vue_request_forward",
        command = "typescript.tsserverRequest",
        arguments = {
          command,
          payload,
        },
      }, { bufnr = context.bufnr }, function(_, r)
        local response_data = { { id, r.body } }
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify("tsserver/response", response_data)
      end)
    end
  end,
})

lsp.enable({ "ltex", "vtsls", "vue_ls" })
