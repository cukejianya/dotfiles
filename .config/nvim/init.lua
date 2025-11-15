-- 1) Options (the 'set' stuff)
local o, wo, bo = vim.o, vim.wo, vim.bo
--[[
o  = vim.o   → Global options
    • Applies to all buffers and windows
    • Example: o.termguicolors = true

wo = vim.wo  → Window-local options
    • Applies to the current window only
    • Example: wo.number = true

bo = vim.bo  → Buffer-local options
    • Applies to the current buffer (file) only
    • Example: bo.expandtab = true
]]

o.compatible = false
vim.cmd("filetype on")

-- Tab-completion for file paths
o.path = o.path .. ",**"
o.wildmenu = true

-- Encoding and formatting
o.encoding = "UTF-8"
o.textwidth = 79
bo.tabstop = 2
bo.shiftwidth = 2
bo.expandtab = true
bo.autoindent = true
bo.smartindent = true
o.backspace = "2"
o.list = true
o.hidden = true
o.colorcolumn = "81"

-- UI
wo.number = true
wo.relativenumber = true
wo.cursorline = true
o.hlsearch = true
o.splitbelow = true
o.splitright = true
o.wrap = false

-- Search behavior
o.ignorecase = true
o.smartcase = true
o.incsearch = true

-- Undo and formatting
o.undofile = true
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
map({ "n", "v" }, "<leader>y", [["+y]], opts)    -- yank to system clipboard
map("n", "<leader>p", [["+p]], opts)

----------------

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
require("config.lazy")

vim.o.foldcolumn = '0' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

vim.keymap.set('n', '<leader>r', ':source ~/.config/nvim/init.vim<CR>')
vim.keymap.set('n', '<leader>csv', 
":4d<CR>" ..
":1,2d<CR>" ..
":$d<CR>" ..
":%s/\\s*|\\s*/|/g<CR>" ..
":%s/^|//g<CR>" ..
":%s/|$//g<CR>" ..
":%s/|/,/g<CR>"
)

vim.opt.mouse = ""

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__autosave__", { clear = true })
autocmd("VimLeavePre", {
	group = "__autosave__",
	command = ":mksession!",
})

local answer = vim.fn.confirm( "Open saved session?",  "&Yes\n&No",    2)

if answer == 1 then
	vim.cmd("source Session.vim")
	end
