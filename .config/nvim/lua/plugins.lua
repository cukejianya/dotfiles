-- This file can be loaded by calling `lua require('plugins')` from your init.vim
require("lazy").setup({

  { 'navarasu/onedark.nvim', lazy = false },
  {
    'neovim/nvim-lspconfig', -- Configurations for Nvim LSP
    lazy = false
  },
  'mfussenegger/nvim-jdtls',
  'mfussenegger/nvim-lsp-compl',
  'kyazdani42/nvim-web-devicons', --optional, for file icons
  'kyazdani42/nvim-tree.lua',
  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
  },
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',

  { 'mfussenegger/nvim-dap', event = 'VeryLazy'},
  'rcarriga/nvim-dap-ui',
  'theHamsta/nvim-dap-virtual-text',
  'lukas-reineke/indent-blankline.nvim',
  {
    'nvim-telescope/telescope.nvim',
    version = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  'nvim-telescope/telescope-ui-select.nvim',
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons' }
  },
  'lewis6991/gitsigns.nvim',
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate'
  },
  {
    'akinsho/git-conflict.nvim',
    event = "VeryLazy",
    version = "*",
    config = function()
      require('git-conflict').setup()
    end
  },
  {
    'scalameta/nvim-metals',
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  'mhartington/formatter.nvim',
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    }
  },
  {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    -- Your DBUI configuration
    vim.g.db_ui_use_nerd_fonts = 1
  end,
}
  })
