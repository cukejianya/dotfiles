local custom_filename = require('lualine.components.filename'):extend()
local highlight = require'lualine.highlight'
local default_status_colors = { saved = '#ABB2BF', modified = '#e06c75' }

function custom_filename:init(options)
  custom_filename.super.init(self, options)
  self.status_colors = {
    saved = highlight.create_component_highlight_group(
      {fg = default_status_colors.saved}, 'filename_status_saved', self.options),
    modified = highlight.create_component_highlight_group(
      {fg = default_status_colors.modified}, 'filename_status_modified', self.options),
  }
  if self.options.color == nil then self.options.color = '' end
end

function custom_filename:update_status()
  local data = custom_filename.super.update_status(self)
  data = highlight.component_format_highlight(vim.bo.modified
                                              and self.status_colors.modified
                                              or self.status_colors.saved) .. data
  return data
end

require('lualine').setup {
  sections = {
    lualine_b = { custom_filename, 'diff', 'diagnostics' },
    lualine_c = {'branch'}
  }
}
