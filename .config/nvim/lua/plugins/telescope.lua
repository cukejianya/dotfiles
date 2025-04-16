return {
  {
    event = "VeryLazy",
    "nvim-telescope/telescope.nvim",
    version = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
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

          file_browser = {
            theme = "ivy",
            initial_browser = "tree",
            -- searching activates a `telescope.find_files` like finder
            -- you can use this to enter directories and remove ( move, copy) files to
            -- selected dir (or selected dir of file) etc.
            auto_depth = true,
            depth = 1,

            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
              ["i"] = {
                -- your custom insert mode mappings
              },
              ["dd"] = {
                -- your custom normal mode mappings
              },
            },
          },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
          fzf = {},
        },
      })

      require("telescope").load_extension("file_browser")
      require("telescope").load_extension("ui-select")
      vim.g.rooter_patterns = { ".git", "Makefile", "package.json" }

      vim.keymap.set("n", "<leader>k", ":Telescope file_browser<CR>")
      vim.keymap.set("n", "<space>y", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "gr", builtin.lsp_references, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fs", builtin.grep_string, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end,
  },
}
