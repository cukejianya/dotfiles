-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local lspconfig = require('lspconfig')

vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- Set up nvim-cmp.
local cmp = require 'cmp'

local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  formatting = {
    format = function(entry, vim_item)
      -- Kind icons
      -- This concatonates the icons with the name of the item kind
      vim_item.kind = string.format('%s (%s)', require('lsp_kind_icons')[vim_item.kind], vim_item.kind)
      -- Source
      vim_item.menu = ({
        buffer = "[Buffer]",
        nvim_lsp = "[LSP]",
        luasnip = "[LuaSnip]",
        nvim_lua = "[Lua]",
        latex_symbols = "[LaTeX]",
      })[entry.source.name]
      return vim_item
    end
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' }, -- Required
    { name = 'luasnip' },  -- For luasnip users.
  }, {
    { name = 'buffer' },
    { name = 'path' }
  })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
  }, {
    { name = 'buffer' },
  })
})

-- Set up lspconfig;
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

-- Ensure the servers above are installed
require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  automatic_installation = true,
  ensure_installed = {
    "cssls",
    "hls",
    "jsonls",
    "lua_ls",
    "marksman",
    "sqlls",
    "spectral", -- OpenAPI
    "tsserver",
    "yamlls"
  },
}

lspconfig.lua_ls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.lemminx.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.yamlls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.yamlls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.cssls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.hls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.jsonls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.marksman.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.sqlls.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.spectral.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

lspconfig.tsserver.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
  filetypes = { "javascript", "typescript", "typescriptreact", "typescript.tsx" },
}

local lsp = {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

return lsp
