return {
  {
    event = "VeryLazy",
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "airblade/vim-rooter",
    },
    config = function()
      local builtin = require("telescope.builtin")
      local actions = require("telescope.actions")

      require("telescope").setup({

        defaults = {
          path_display = { "smart" },
          vimgrep_arguments = {
            "rg",
            "--hidden",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--glob=!**/.git/*",
            "--glob=!**/node_modules/*",
            "--glob=!**/target/*",
          },
        },

        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "-g",
              "!**/.git/*",
              "-g",
              "!**/node_modules/*",
              "-g",
              "!**/target/*",
            },
          },

          buffers = {
            sort_lastused = true,
            mappings = {
              n = {
                ["dd"] = actions.delete_buffer,
              },
            },
          },

          oldfiles = {
            cwd_only = true,
          },

          lsp_references = {
            theme = "dropdown",
            initial_mode = "normal",
          },

          lsp_definitions = {
            theme = "dropdown",
            initial_mode = "normal",
          },

          lsp_declarations = {
            theme = "dropdown",
            initial_mode = "normal",
          },

          lsp_implementations = {
            theme = "dropdown",
            initial_mode = "normal",
          },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
          fzf = {},
        },
      })

      require("telescope").load_extension("ui-select")
      vim.g.rooter_patterns = { ".git", "Makefile", "package.json" }

      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, {})
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "gr", builtin.lsp_references, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fs", builtin.grep_string, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      vim.keymap.set("n", "<leader>fm", function()
        builtin.treesitter({ symbols = { "method", "function" }, show_line = false })
      end, {})
    end,
  },
}
