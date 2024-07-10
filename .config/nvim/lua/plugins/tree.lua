local HEIGHT_RATIO = 0.8  -- You can change this
local WIDTH_RATIO = 0.8   -- You can change this too

local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set('n', 'd', api.tree.change_root_to_node, opts('dir_down'))
  vim.keymap.set('n', 'u', api.tree.change_root_to_parent, opts('dir_up'))

  vim.keymap.set('n', 'Z', api.node.run.system, opts('Run System'))
end



return {
  'kyazdani42/nvim-tree.lua',

  config = function()
    require("nvim-tree").setup({
      on_attach = on_attach,
      sort_by = "case_sensitive",
      view = {
        adaptive_size = true,
        float = {
          enable = true,
          open_win_config = function()
            local screen_w = vim.opt.columns:get()
            local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
            local window_w = screen_w * WIDTH_RATIO
            local window_h = screen_h * HEIGHT_RATIO
            local window_w_int = math.floor(window_w)
            local window_h_int = math.floor(window_h)
            local center_x = (screen_w - window_w) / 2
            local center_y = ((vim.opt.lines:get() - window_h) / 2)
            - vim.opt.cmdheight:get()
            return {
              border = 'rounded',
              relative = 'editor',
              row = center_y,
              col = center_x,
              width = window_w_int,
              height = window_h_int,
            }
          end,
        },
        width = function()
          return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
        end,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
    })

    vim.keymap.set('n', '<leader>k', ':NvimTreeToggle<CR>')
    vim.keymap.set('n', '<leader>y', ':NvimTreeFindFile<CR>')
  end
}
