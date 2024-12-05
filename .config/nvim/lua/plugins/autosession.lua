return {
  {
    "rmagatti/auto-session",
    dependencies = {
      "nvim-telescope/telescope.nvim", -- Only needed if you want to use sesssion lens
    },
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      auto_restore = true, -- Enables/disables auto restoring session on start
      auto_save = true, -- Enables/disables auto saving session on exit
      allowed_dirs = { "~/workspace", "~/development" },
      use_git_branch = true, -- Include git branch name in session name
      close_unsupported_windows = true, -- Close windows that aren't backed by normal file before autosaving a session
      continue_restore_on_error = true, -- Keep loading the session even if there's an error
    },
  },
}
