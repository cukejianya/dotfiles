return {
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    ft = "markdown",
    opts = {
      preview = {
        enable = true,
        enable_hybrid_mode = true,
        hybrid_modes = { "n", "no", "c" },
        linewise_hybrid_mode = true,
      },
    },
    priority = 49,
    keys = {
      { "<leader>m", "<cmd>Markview toggle<cr>", desc = "NeoTree" },
    },
  },
}
