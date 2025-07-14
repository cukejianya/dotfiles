local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local utils = require("telescope.utils")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

local M = {}
local function gen_from_git_worktree()
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 30 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    return displayer({
      { entry.worktree_name },
      { entry.ordinal },
      -- { string.sub(entry.ordinal, 2, -2), "TelescopeResultsIdentifier" },
    })
  end

  return function(entry)
    if entry == "" then
      return nil
    end

    local splitted = utils.max_split(entry)
    local path = splitted[1]
    local branch_name = splitted[3]
    local sha = splitted[2]
    local worktree_dir_name = vim.fn.fnamemodify(path, ":t")

    return {
      value = path,
      worktree_name = worktree_dir_name,
      ordinal = branch_name,
      sha = sha,
      display = make_display,
    }
  end
end

local git_change_worktree = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()

  if selection == nil then
    utils.__warn_no_selection("actions.git_change_worktree")
    return
  end
  local session_filename = ".nvim_worktree_session.vim"
  local prev_session_file = vim.fn.getcwd() .. "/" .. session_filename
  if vim.fn.filereadable(prev_session_file) == 1 then
    vim.cmd("silent! mksession! " .. prev_session_file)
  else
    vim.cmd("silent! mksession " .. prev_session_file)
  end

  actions.close(prompt_bufnr)

  if vim.fn.bufnr("$") > 1 then
    vim.cmd("%bd")
  end

  vim.cmd("cd " .. selection.value)

  utils.notify("git_change_worktree", {
    msg = string.format("Changing work tree: %s", selection.worktree_name),
    level = "INFO",
  })

  local curr_session_file = vim.fn.getcwd() .. "/" .. session_filename
  if vim.fn.filereadable(curr_session_file) == 1 then
    vim.cmd("silent! source" .. curr_session_file)
  else
    vim.cmd("e") -- new empty buffer
  end

  -- if vim.fn.bufexists("#") then
  --   vim.cmd("bd#")
  -- end
end

local git_worktrees = function(opts)
  opts = opts or {}
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, gen_from_git_worktree())
  opts.show_branch = true
  opts.previewer = false

  local git_worktree_cmd = { "git", "worktree", "list" }

  pickers
    .new(opts, {
      prompt_title = "Git Worktree",
      finder = finders.new_oneshot_job(git_worktree_cmd, opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function()
        actions.select_default:replace(git_change_worktree)
        return true
      end,
    })
    :find()
end

M.setup = function()
  vim.keymap.set("n", "<leader>fw", git_worktrees)
end

return M
