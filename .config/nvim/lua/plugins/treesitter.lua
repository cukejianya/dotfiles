return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "nvim-treesitter/nvim-treesitter-refactor",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "nvim-treesitter/playground",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        -- A list of parser names, or "all" (the five listed parsers should always be installed)
        ensure_installed = {
          "c",
          "vimdoc",
          "java",
          "javascript",
          "json",
          "lua",
          "query",
          "tsx",
          "vim",
          "yaml",
          "sql",
          "markdown_inline",
          "regex",
        },

        indent = { enable = true },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,

        ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
        -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

        highlight = {
          enable = true,

          -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
          -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
          -- the name of the parser)
          -- list of language that will be disabled
          disable = {},

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to text object
            keymaps = {
              -- Keymaps for method text objects
              ["am"] = "@method.outer", -- Select around the method
              ["im"] = "@method.inner", -- Select inside the method
              -- Function text objects
              ["af"] = "@function.outer", -- Select around the function
              ["if"] = "@function.inner", -- Select inside the function
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- Enable jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@method.outer",
              ["]f"] = "@function.outer", -- Jump to the start of the next function
            },
            goto_next_end = {
              ["]M"] = "@method.outer",
              ["]F"] = "@function.outer", -- Jump to the end of the next function
            },
            goto_previous_start = {
              ["[m"] = "@method.outer",
              ["[f"] = "@function.outer", -- Jump to the start of the previous function
            },
            goto_previous_end = {
              ["[M"] = "@method.outer",
              ["[F"] = "@function.outer", -- Jump to the end of the previous function
            },
          },
        },
        playground = {
          enable = true, -- Enable the Playground
          updatetime = 25, -- Debounced time for highlighting nodes
          persist_queries = false, -- Whether queries should persist across sessions
        },
      })
    end,
  },
}
