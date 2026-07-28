local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local usercmd = vim.api.nvim_create_user_command

local log_dir = vim.fn.stdpath("log")
local session_dir = vim.fn.stdpath("state") .. "/sessions"
vim.fn.mkdir(session_dir, "p")

local get_session_file = function()
  local root = vim.fs.root(0, {
    ".git",
    "package.json",
    ".project",
    "BUILD.bazel",
  }) or vim.fn.getcwd()
  local filename = root:gsub("^[/\\]+", ""):gsub("[/\\:]", "_"):gsub("[.]", "")
  return vim.fn.fnameescape(session_dir) .. "/" .. filename
end

-- Autosave Session during exit
augroup("__autosave__", { clear = true })
autocmd("VimLeavePre", {
  group = "__autosave__",
  callback = function()
    vim.cmd.mksession({ args = { get_session_file() }, bang = true })
  end,
})

augroup("__autoload__", { clear = true })
autocmd("VimEnter", {
  group = "__autoload__",
  callback = function()
    local session_file = get_session_file()
    if vim.uv.fs_stat(session_file) then
      local answer = vim.fn.confirm("Open saved session?", "&Yes\n&No", 2)

      if answer == 1 then
        vim.cmd.source({ args = { session_file } })
      end
    end
  end,
})

-- LSP Commands
usercmd("LspInfo", function()
  vim.print(vim.lsp.get_clients())
end, {})

usercmd("LspLog", function()
  vim.cmd.edit({ args = { log_dir .. "/lsp.log" } })
end, {})
