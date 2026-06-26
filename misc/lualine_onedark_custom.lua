-- Copyright (c) 2020-2021 shadmansaleh
-- MIT license, see LICENSE for more details.
-- Credit: Zoltan Dalmadi(lightline)
-- stylua: ignore
local colors = {
  blue   = '#61afef',
  green  = '#98c379',
  purple = '#c678dd',
  cyan   = '#56b6c2',
  red1   = '#e06c75',
  red2   = '#be5046',
  yellow = '#e5c07b',
  fg     = '#abb2bf',
  bg     = '#1a212e',
  gray1  = '#828997',
  gray2  = '#2c323c',
  gray3  = '#3e4452',
}

return {
  normal = {
    a = { fg = colors.green, bg = colors.bg },
    b = { fg = colors.fg, bg = colors.bg },
    c = { fg = colors.fg, bg = colors.bg },
  },
  command = { a = { fg = colors.yellow, bg = colors.bg } },
  insert = { a = { fg = colors.blue, bg = colors.bg, gui = 'bold' } },
  visual = { a = { fg = colors.purple, bg = colors.bg, gui = 'bold' } },
  terminal = { a = { fg = colors.cyan, bg = colors.bg, gui = 'bold' } },
  replace = { a = { fg = colors.red1, bg = colors.bg, gui = 'bold' } },
  inactive = {
    a = { fg = colors.gray1, bg = colors.bg, gui = 'bold' },
    b = { fg = colors.gray1, bg = colors.bg },
    c = { fg = colors.gray1, bg = colors.bg },
  },
}
