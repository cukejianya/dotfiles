-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.

vim.opt.completeopt={'menu', 'menuone', 'noselect'}

-- Set up nvim-cmp.
local cmp = require'cmp'

cmp.setup({
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
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
        { name = 'luasnip' }, -- For luasnip users.
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

local common_on_attach = function(client, bufr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', "gr", vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', "<leader>df", vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', "<leader>r", vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', "<leader>ac", vim.lsp.buf.code_action, bufopts)
end


local lsp = {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

return lsp
