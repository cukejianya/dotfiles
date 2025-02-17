return {
  { "norcalli/nvim-colorizer.lua", event = "VeryLazy" },
  { "folke/zen-mode.nvim", event = "VeryLazy" },
  {
    "navarasu/onedark.nvim",
    lazy = false,
    opts = {
      style = "deep",
      toggle_style_key = "<leader>sc",
      highlights = {
        DashboardHeader = { fg = "$cyan" },
      },
    },
    config = function(_, opts)
      require("onedark").setup(opts)
      require("onedark").load()
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
    event = "InsertEnter",
  },
}
