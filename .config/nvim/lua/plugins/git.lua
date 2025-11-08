return {
  "akinsho/git-conflict.nvim",
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = { "Git", "Gvsplit" },
  },
  {
    "claydugo/browsher.nvim",
    cmd = "Browsher",
    config = function()
      -- Specify empty to use below default options
      require("browsher").setup({
        open_cmd = "open",
        providers = {
          -- ["github.com"] = {
          --   url_template = "%s/blob/%s/%s",
          --   single_line_format = "#L%d",
          --   multi_line_format = "#L%d-L%d",
          -- },
          ["ghe.spotify.net"] = {
            url_template = "%s/blob/%s/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d-L%d",
          },
        },
      })
    end,
  },
}
