return {
  'kyazdani42/nvim-web-devicons', --optional, for file icons
  {
    'navarasu/onedark.nvim',
    lazy = false,
    opts = {
        style = 'cool',
        toggle_style_key = "<leader>sc"
    },
    config = function(_, opts)
      require('onedark').setup(opts)
      require('onedark').load()
    end
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons' }
  },
  {
    'norcalli/nvim-colorizer.lua',
    lazy = false,
    opts = {},
  },
}
