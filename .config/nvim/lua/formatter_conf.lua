
require('formatter').setup({
  filetype = {
    java = {
      -- Define the formatter for Java files
      function()
        return {
          exe = "/Users/chinedumu/.sdkman/candidates/java/17.0.7-amzn/bin/java",
          args = {
            "-jar",
            "$HOME/.dotfiles/misc/google-java-format-1.21.0-all-deps.jar",
            "--replace"
          },
          stdin = false,
        }
      end
    }
  }
})

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })
autocmd("BufWritePost", {
  group = "__formatter__",
  command = ":FormatWrite",
})
