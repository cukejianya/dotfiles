-- 1) Options (the 'set' stuff)
--[[
vim.o   → Global options
    • Applies to all buffers and windows
    • Example: o.termguicolors = true

vim.wo  → Window-local options
    • Applies to the current window only
    • Example: wo.number = true

= vim.bo  → Buffer-local options
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

-- =========================================================
-- Keymaps
-- =========================================================

-- Leader key
vim.g.mapleader = " "

local map = vim.keymap.set
local opts = { silent = true }

-- Toggle relative number line
map("n", "<leader>r", ":setlocal relativenumber!<CR>", opts)

-- Reload and edit vim config file
map("n", "<leader>ve", ":e $MYVIMRC<CR>", opts)
map("n", "<leader>vr", ":source $MYVIMRC<CR>", opts)

-- Buffer navigation
map("n", "<leader>b", ":bp<CR>", opts)
map("n", "<leader>n", ":bn<CR>", opts)
map("n", "<leader>e", ":Bd<CR>", opts)

-- Disable arrow keys
map("", "<Up>", "<Nop>", opts)
map("", "<Down>", "<Nop>", opts)
map("", "<Left>", "<Nop>", opts)
map("", "<Right>", "<Nop>", opts)

-- Split navigation (Ctrl + hjkl)
map("n", "<C-J>", "<C-W><C-J>", opts)
map("n", "<C-K>", "<C-W><C-K>", opts)
map("n", "<C-L>", "<C-W><C-L>", opts)
map("n", "<C-H>", "<C-W><C-H>", opts)

-- Use Clipboard
map({ "n", "v" }, "<leader>y", [["+y]], opts) -- yank to system clipboard
map("n", "<leader>p", [["+p]], opts)

----------------

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
require("config.lazy")

vim.o.foldcolumn = "0" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

vim.keymap.set("n", "<leader>r", ":source ~/.config/nvim/init.vim<CR>")
vim.keymap.set(
  "n",
  "<leader>csv",
  ":4d<CR>"
    .. ":1,2d<CR>"
    .. ":$d<CR>"
    .. ":%s/\\s*|\\s*/|/g<CR>"
    .. ":%s/^|//g<CR>"
    .. ":%s/|$//g<CR>"
    .. ":%s/|/,/g<CR>"
)

vim.opt.mouse = ""

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__autosave__", { clear = true })
autocmd("VimLeavePre", {
  group = "__autosave__",
  command = ":mksession!",
})

local answer = vim.fn.confirm("Open saved session?", "&Yes\n&No", 2)

if answer == 1 then
  vim.cmd("source Session.vim")
end
