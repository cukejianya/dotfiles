return {
  "mhartington/formatter.nvim",
  event = "VeryLazy",
  cmd = {
    "Format",
    "FormatWrite",
  },

  config = function()
    local util = require("formatter.util")

    require("formatter").setup({
      filetype = {
        java = {
          -- Define the formatter for Java files
          function()
            return {
              exe = "/Users/chinedumu/.sdkman/candidates/java/17.0.7-amzn/bin/java",
              args = {
                "-jar",
                "$HOME/.dotfiles/misc/google-java-format-1.21.0-all-deps.jar",
                "--replace",
              },
              stdin = false,
            }
          end,
        },
        lua = {
          -- "formatter.filetypes.lua" defines default configurations for the
          -- "lua" filetype
          function()
            -- Full specification of configurations is down below and in Vim help
            -- files
            return {
              exe = "stylua",
              args = {
                "--indent-type",
                "Spaces",
                "--indent-width",
                "2",
                "--search-parent-directories",
                "--stdin-filepath",
                util.escape_path(util.get_current_buffer_file_path()),
                "--",
                "-",
              },
              stdin = true,
            }
          end,
        },
        -- xml = {
        --   require("formatter.filetypes.xml").xmllint,
        -- },
      },
    })
    local augroup = vim.api.nvim_create_augroup
    local autocmd = vim.api.nvim_create_autocmd
    augroup("__formatter__", { clear = true })
    autocmd("BufWritePost", {
      group = "__formatter__",
      command = ":FormatWrite",
    })
  end,
}
-- "formatter.filetypes.lua" defines default configurations for the
