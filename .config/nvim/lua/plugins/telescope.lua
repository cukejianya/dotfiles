return {
  {
    "nvim-telescope/telescope.nvim",
    version = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "airblade/vim-rooter",
    },
    config = function()
      require("telescope").setup({
        defaults = {
          path_display = { "smart" },
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          },
          live_grep = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
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
              ["n"] = {
                -- your custom normal mode mappings
              },
            },
          },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
        },
      })
      require("telescope").load_extension("file_browser")
      require("telescope").load_extension("ui-select")
      vim.g.rooter_patterns = { ".git", "Makefile", "package.json" }
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>k", ":Telescope file_browser<CR>")
      vim.keymap.set("n", "<space>y", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "gr", builtin.lsp_references, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fs", builtin.grep_string, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

      -- vim.api.nvim_create_autocmd("VimEnter", {
      --   callback = function()
      --     vim.cmd("Rooter")
      --     if vim.fn.argv(0) == "" then
      --       -- Wipe out the initial "No Name" buffer
      --       vim.cmd("bwipeout")
      --       require("telescope.builtin").find_files(require("telescope.themes").get_dropdown({
      --         mappings = {
      --           i = {
      --             ["<Esc>"] = function() end, -- Disable `<Esc>` in insert mode
      --             ["<C-c>"] = function() end, -- Disable `<C-c>` in insert mode
      --           },
      --           n = {
      --             ["q"] = function() end, -- Disable `q` in normal mode
      --             ["<Esc>"] = function() end, -- Disable `<Esc>` in normal mode
      --           },
      --         },
      --         layout_strategy = "horizontal", -- Or "vertical", "center"
      --         layout_config = {
      --           width = 0.99,
      --           height = 0.99,
      --           prompt_position = "top",
      --         },
      --       }))
      --     end
      --   end,
      -- })
    end,
  },
}
