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


-- Costum csv formatter
map(
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

map("n", "<leader>hh", function()
  local project_path = vim.fs.relpath(vim.fs.root(0, ".git"), vim.api.nvim_buf_get_name(0))
  print("Copy path " .. project_path)
  vim.fn.setreg("+", project_path)
end, opts)

map("v", "<leader>hh", function()
  local startline = vim.fn.line("v")
  local endline = vim.fn.line(".")
  if startline > endline then
    endline, startline = startline, endline
  end
  local project_path = vim.fs.relpath(vim.fs.root(0, ".git"), vim.api.nvim_buf_get_name(0))
  local project_path_with_lines = project_path .. "#L" .. startline .. "-" .. endline
  print("Copy path " .. project_path_with_lines)
  vim.fn.setreg("+", project_path_with_lines)
end, opts)
