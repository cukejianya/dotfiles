return {
  { "akinsho/git-conflict.nvim", version = "v2.0.9", config = true },
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
      local providers = {
        -- ["github.com"] = {
        --   url_template = "%s/blob/%s/%s",
        --   single_line_format = "#L%d",
        --   multi_line_format = "#L%d-L%d",
        -- },
      }
      -- Private work overlay. pcall skips it if the file is absent.
      local ok, extra = pcall(dofile, vim.fn.expand("~/.dotfiles-work/nvim/browsher.lua"))
      if ok then
        providers = vim.tbl_extend("force", providers, extra)
      end
      require("browsher").setup({ open_cmd = "open", providers = providers })
    end,
  },
}
