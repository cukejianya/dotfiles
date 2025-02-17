return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",

    config = function()
      -- local logo = [[
      -- ⠀⠀⢀⣤⣤⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀
      -- ⠀⠀⢸⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀
      -- ⠀⠀⠘⠉⠉⠙⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀
      -- ⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀
      -- ⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀
      -- ⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀
      -- ⠀⠀⠀⠀⣴⣿⣿⣿⠟⣿⣿⣿⣷⠀⠀⠀⠀
      -- ⠀⠀⠀⣰⣿⣿⣿⡏⠀⠸⣿⣿⣿⣇⠀⠀⠀
      -- ⠀⠀⢠⣿⣿⣿⡟⠀⠀⠀⢻⣿⣿⣿⡆⠀⠀
      -- ⠀⢠⣿⣿⣿⡿⠀⠀⠀⠀⠀⢿⣿⣿⣷⣤⡄
      -- ⢀⣾⣿⣿⣿⠁⠀⠀⠀⠀⠀⠈⠿⣿⣿⣿⡇
      -- ]]

      -- local logo = [[
      --   ░  ░░░░░░░░░      ░░░  ░░░░  ░░       ░░░░      ░░
      --   ▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒   ▒▒   ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒
      --   ▓  ▓▓▓▓▓▓▓▓  ▓▓▓▓  ▓▓        ▓▓  ▓▓▓▓  ▓▓  ▓▓▓▓  ▓
      --   █  ████████        ██  █  █  ██  ████  ██        █
      --   █        ██  ████  ██  ████  ██       ███  ████  █
      -- ]]

      -- logo = string.rep("\n", 8) .. logo .. "\n\n"

      local header = {
        [[                                                                       ]],
        [[                                                                     ]],
        [[       ████ ██████           █████      ██                     ]],
        [[      ███████████             █████                             ]],
        [[      █████████ ███████████████████ ███   ███████████   ]],
        [[     █████████  ███    █████████████ █████ ██████████████   ]],
        [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
        [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
        [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
        [[                                                                       ]],
      }

      require("dashboard").setup({
        config = {
          -- header = vim.split(logo, "\n"),
          header = header,
          disable_move = true,
          packages = { enable = true },
          shortcut = {
            {
              icon = " ",
              group = "Changed",
              desc = "Files", -- Blue
              action = "Telescope find_files",
              key = "f",
            },
            {
              desc = "󰆼 Database",
              group = "Label", -- Purple
              action = function()
                vim.cmd("bwipeout")
                vim.cmd("DBUI")
              end,
              key = "d",
            },
            {
              desc = " Dotfiles",
              group = "Tag", -- Green
              action = "Telescope find_files cwd=$HOME/.dotfiles/.config/nvim",
              key = "c",
            },
            { desc = "󰊳 Update", group = "Type", action = "Lazy update", key = "u" },
          },
        },
      })
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
}
