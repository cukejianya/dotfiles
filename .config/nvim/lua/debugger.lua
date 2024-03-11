vim.fn.sign_define(
  "DapBreakpoint",
  { text = "", texthl = "special", linehl = "", numhl = "" }
)

local dap, dapui = require("dap"), require("dapui")

local map = vim.keymap.set
map("n", "<leader>dd", ":JdtRefreshDebugConfigs<CR>")
map("n", "<leader>dc", ":lua require'dap'.continue()<CR>")
map("n", "<leader>dn", ":lua require'dap'.step_over()<CR>")
map("n", "<leader>di", ":lua require'dap'.step_into()<CR>")
map("n", "<leader>dt", ":lua require'jdtls'.test_nearest_method()<CR>")
map("n", "<leader>db", ":lua require'dap'.toggle_breakpoint()<CR>")
map("n", "<leader>dB", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
map("n", "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
map("n", "<leader>dk", ":lua require'dapui'.toggle()<CR>")
map("n", "<leader>do", ":lua require'dapui'.open()<CR>")
map("n", "<leader>d=", ":lua require'dapui'.open({ reset = true })<CR>")
map("n", "<leader>dq", ":lua require'dapui'.close()<CR>")

require("nvim-dap-virtual-text").setup()
dapui.setup()

-- dap.listeners.after.event_initialized["dapui_config"] = function()
  -- dapui.open()
-- end
-- dap.listeners.before.event_terminated["dapui_config"] = function()
  -- dapui.close()
-- end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end
