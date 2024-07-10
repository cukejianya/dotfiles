return {
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  },
  {
    'akinsho/git-conflict.nvim',
    event = "VeryLazy",
    version = "*",
    config = function()
      require('git-conflict').setup()
    end
  },
  {
    'tpope/vim-fugitive',
    event = 'VeryLazy',
    cmd = {'Git', 'Gvsplit'}
  },
}
