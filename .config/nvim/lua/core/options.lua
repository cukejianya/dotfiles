--[[
vim.o   → Global options
    • Applies to all buffers and windows
    • Example: o.termguicolors = true

vim.wo  → Window-local options
    • Applies to the current window only
    • Example: wo.number = true

vim.bo  → Buffer-local options
    • Applies to the current buffer (file) only
    • Example: bo.expandtab = true
]]

vim.o.compatible = false
vim.cmd("filetype on")

-- Tab-completion for file paths
vim.o.path = vim.o.path .. ",**"
vim.o.wildmenu = true

-- Encoding and formatting
vim.o.encoding = "UTF-8"
vim.o.textwidth = 79
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.backspace = "2"
vim.o.list = true
vim.o.hidden = true
vim.o.colorcolumn = "81"

-- UI
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.hlsearch = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.wrap = false

local symbols = { Error = "󰅙", Info = "󰋼", Hint = "󰌵", Warn = "" }

for name, icon in pairs(symbols) do
  local hl = "DiagnosticSign" .. name
  vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
end

-- Search behavior
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

-- Undo and formatting
vim.o.undofile = true
vim.opt.formatoptions:remove("c")
vim.opt.formatoptions:remove("r")
vim.opt.formatoptions:remove("o")

-- Wildignore patterns
vim.opt.wildignore:append({
  "*/tmp/*",
  "*/node_modules/*",
  "*/bower_components/*",
  "*/build/*",
  "*.swp",
  "*/venv/*",
})

vim.g.loaded_netrw = 1

vim.o.foldcolumn = "0" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

vim.opt.mouse = ""
