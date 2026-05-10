return {
  { "norcalli/nvim-colorizer.lua", cmd = "ColorizerToggle" },
  {
    "folke/twilight.nvim",
    opts = {
      expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
        "function",
        "method",
        "table",
        "if_statement",
      },
    },
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      window = {
        width = 0.85, -- width will be 85% of the editor width
        options = {
          -- signcolumn = "no", -- disable signcolumn
          -- number = false, -- disable number column
          -- relativenumber = false, -- disable relative numbers
          cursorline = false, -- disable cursorline
          cursorcolumn = false, -- disable cursor column
          -- foldcolumn = "0", -- disable fold column
          -- list = false, -- disable whitespace characters
        },
      },
      plugins = {
        -- disable some global vim options (vim.o...)
        -- comment the lines to not apply the options
        options = {
          enabled = true,
          ruler = false, -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
          -- you may turn on/off statusline in zen mode by setting 'laststatus'
          -- statusline will be shown only if 'laststatus' == 3
          laststatus = 0, -- turn off the statusline in zen mode
        },
        twilight = { enabled = false },
        gitsigns = { enabled = true }, -- disables git signs
        tmux = { enabled = true }, -- disables the tmux statusline
        -- this will change the font size on kitty when in zen mode
        -- to make this work, you need to set the following kitty options:
        -- - allow_remote_control socket-only
        -- - listen_on unix:/tmp/kitty
        kitty = {
          enabled = false,
          font = "20", -- font size increment
        },
      },
    },
  },
  {
    "navarasu/onedark.nvim",
    lazy = false,
    enabled = true,
    opts = {
      style = "deep",
      toggle_style_key = "<leader>sc",
      highlights = {

        -- Java specific overrides
        -- low-color Java
        ["@variable.java"] = { fg = "$fg" },
        ["@variable.builtin.java"] = { fg = "$fg", fmt = "italic" },
        ["@variable.member.java"] = { fg = "$fg" },
        ["@parameter.java"] = { fg = "$fg", fmt = "italic" },

        ["@function.java"] = { fg = "$fg" },
        ["@function.method.java"] = { fg = "$fg" },
        ["@method.java"] = { fg = "$fg" },
        ["@constructor.java"] = { fg = "$fg", fmt = "bold" },

        ["@type.java"] = { fg = "$fg", fmt = "bold" },
        ["@type.builtin.java"] = { fg = "$fg" },
        ["@namespace.java"] = { fg = "$fg" },

        ["@property.java"] = { fg = "$fg" },
        ["@field.java"] = { fg = "$fg" },

        ["@keyword.java"] = { fg = "$light_grey", fmt = "italic" },
        ["@keyword.conditional.java"] = { fg = "$light_grey", fmt = "italic" },
        ["@keyword.repeat.java"] = { fg = "$light_grey", fmt = "italic" },
        ["@keyword.function.java"] = { fg = "$light_grey", fmt = "italic" },
        ["@keyword.operator.java"] = { fg = "$light_grey", fmt = "italic" },
        ["@operator.java"] = { fg = "$light_grey" },

        ["@annotation.java"] = { fg = "$fg", fmt = "italic" },

        ["@string.java"] = { fg = "$green" },
        ["@string.escape.java"] = { fg = "$light_grey", fmt = "bold" },
        ["@character.java"] = { fg = "$fg" },

        ["@number.java"] = { fg = "$fg" },
        ["@boolean.java"] = { fg = "$fg" },

        ["@punctuation.delimiter.java"] = { fg = "$light_grey" },
        ["@punctuation.bracket.java"] = { fg = "$light_grey" },

        ["@comment.java"] = { fg = "$grey", fmt = "italic" },

        -- gentle fallbacks
        ["@method"] = { fg = "$fg" },
        ["@type"] = { fg = "$fg", fmt = "bold" },
        ["@keyword"] = { fg = "$light_grey", fmt = "italic" },
        ["@string"] = { fg = "$green" },
        ["@comment"] = { fg = "$grey", fmt = "italic" },
      },
    },
    -- config = function(_, opts)
    --   require("onedark").setup(opts)
    --   require("onedark").load()
    -- end,
    -- ~/.config/nvim/lua/plugins/colorscheme.lua
    config = function()
      require("onedark").setup({
        style = "deep",
      })

      require("onedark").load()

      local code_fg = "#abb2bf" -- normal OneDark foreground
      local comment_fg = "#5c6370" -- OneDark comment color

      -- Make ALL syntax look like normal text
      local groups = {
        -- Vim syntax
        "Constant",
        "String",
        "Character",
        "Number",
        "Boolean",
        "Float",
        "Identifier",
        "Function",
        "Statement",
        "Conditional",
        "Repeat",
        "Label",
        "Operator",
        "Keyword",
        "Exception",
        "PreProc",
        "Include",
        "Define",
        "Macro",
        "PreCondit",
        "Type",
        "StorageClass",
        "Structure",
        "Typedef",
        "Special",
        "SpecialChar",
        "Tag",
        "Delimiter",
        "Debug",

        -- Treesitter
        "@variable",
        "@variable.builtin",
        "@variable.parameter",
        "@constant",
        "@constant.builtin",
        "@constant.macro",
        "@module",
        "@label",
        "@string",
        "@string.regex",
        "@string.escape",
        "@character",
        "@number",
        "@boolean",
        "@float",
        "@function",
        "@function.builtin",
        "@function.call",
        "@function.macro",
        "@constructor",
        "@method",
        "@method.call",
        "@keyword",
        "@keyword.function",
        "@keyword.operator",
        "@keyword.return",
        "@keyword.conditional",
        "@keyword.repeat",
        "@operator",
        "@type",
        "@type.builtin",
        "@property",
        "@field",
        "@attribute",
        "@punctuation.delimiter",
        "@punctuation.bracket",
        "@punctuation.special",
      }

      for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, {
          fg = code_fg,
          bg = "NONE",
          bold = false,
          italic = false,
        })
      end

      -- Disable semantic token rainbowing from LSPs
      for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
        vim.api.nvim_set_hl(0, group, {
          fg = code_fg,
          bg = "NONE",
          bold = false,
          italic = false,
        })
      end

      -- Comments ONLY
      vim.api.nvim_set_hl(0, "Comment", {
        fg = comment_fg,
        italic = true,
      })

      vim.api.nvim_set_hl(0, "@comment", {
        fg = comment_fg,
        italic = true,
      })
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
    event = "InsertEnter",
  },
}
