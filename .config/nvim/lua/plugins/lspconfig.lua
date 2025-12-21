local lsp_servers = {
  "bashls",
  "cssls",
  "jsonls",
  "lua_ls",
  "marksman",
  "ltex",
  "sqlls",
  "ts_ls",
  "lemminx",
  "yamlls",
  "pyright",
  "arduino_language_server",
}

local lsp_kind_icons = {
  Text = " ",
  Method = " ",
  Function = " ",
  Constructor = " ",
  Field = " ",
  Variable = " ",
  Class = " ",
  Interface = " ",
  Module = " ",
  Property = " ",
  Unit = " ",
  Value = " ",
  Enum = " ",
  Keyword = " ",
  Snippet = " ",
  Color = " ",
  File = " ",
  Reference = " ",
  Folder = " ",
  EnumMember = " ",
  Constant = " ",
  Struct = " ",
  Event = "",
  Operator = " ",
  TypeParameter = " ",
  Table = "",
  Object = "",
  Tag = "",
  Array = "",
  Boolean = "蘒",
  Number = "",
  String = "",
  Calendar = "",
  Watch = "",
}

return {
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },
  {
    event = "VeryLazy",
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", version = "^1.0.0" },
      { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
    },
    config = function()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = lsp_servers,
      })
    end,
  },
  {
    event = "VeryLazy",
    "neovim/nvim-lspconfig", -- Configurations for Nvim LSP
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "folke/lazydev.nvim",
      "barreiroleo/ltex-extra.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local lsp = require("lsp")
      local lsp_conf = {
        on_attach = lsp.on_attach,
        capabilities = lsp.capabilities(),
      }
      for _, server in ipairs(lsp_servers) do
        lspconfig[server].setup(lsp_conf)
      end

      lspconfig.ltex.on_attach = function(client, buffer)
        require("ltex_extra").setup({})
        lsp.on_attach(client, buffer)
      end

      lspconfig.ts_ls.filetypes = { "javascript", "typescript", "typescriptreact", "typescript.tsx" }
    end,
  },
  "mfussenegger/nvim-jdtls",
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = { "scala", "sbt" },
    opts = function()
      local metals_config = require("metals").bare_config()
      local lsp = require("lsp")
      metals_config.on_attach = lsp.on_attach
      metals_config.capabilities = lsp.capabilities()

      return metals_config
    end,
    config = function(self, metals_config)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = self.ft,
        callback = function()
          require("metals").initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end,
  },
  {
    event = "VeryLazy",
    "hrsh7th/cmp-nvim-lsp",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
  },
  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = "VeryLazy",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")

      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      luasnip.config.setup({})

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
            vim_item.kind = string.format("%s (%s)", lsp_kind_icons[vim_item.kind], vim_item.kind)
            -- Source
            vim_item.menu = ({
              buffer = "[Buffer]",
              nvim_lsp = "[LSP]",
              luasnip = "[LuaSnip]",
              nvim_lua = "[Lua]",
              latex_symbols = "[LaTeX]",
            })[entry.source.name]
            return vim_item
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          -- ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- Required
          { name = "luasnip" }, -- For luasnip users.
          { name = "vim-dadbod-completion" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Set configuration for specific filetype.
      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
        }, {
          { name = "buffer" },
        }),
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
        matching = { disallow_symbol_nonprefix_matching = false },
      })
    end,
  },
}
