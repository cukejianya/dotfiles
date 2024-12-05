return {
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
    "norcalli/nvim-colorizer.lua",
    lazy = false,
    opts = {},
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
  },
}
