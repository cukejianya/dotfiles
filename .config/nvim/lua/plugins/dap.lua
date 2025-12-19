return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function(_, opts)
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "special", linehl = "", numhl = "" })
      vim.api.nvim_create_augroup("DapGroup", { clear = true })

      local dap, dapui = require("dap"), require("dapui")
      local map = vim.keymap.set
      local layouts = {}

      local function layout(name)
        return {
          elements = {
            { id = name },
          },
          enter = true,
          size = 14,
          position = "bottom",
        }
      end
      local name_to_layout = {
        repl = { layout = layout("repl"), index = 0 },
        stacks = { layout = layout("stacks"), index = 0 },
        scopes = { layout = layout("scopes"), index = 0 },
        console = { layout = layout("console"), index = 0 },
        watches = { layout = layout("watches"), index = 0 },
        breakpoints = { layout = layout("breakpoints"), index = 0 },
      }

      for name, config in pairs(name_to_layout) do
        table.insert(layouts, config.layout)
        name_to_layout[name].index = #layouts
      end

      local function toggle_debug_ui(name)
        dapui.close()
        local layout_config = name_to_layout[name]

        if layout_config == nil then
          error(string.format("bad name: %s", name))
        end

        dapui.toggle(layout_config.index)
      end

      map("n", "<leader>dr", function()
        toggle_debug_ui("repl")
      end)
      map("n", "<leader>ds", function()
        toggle_debug_ui("stacks")
      end)
      map("n", "<leader>dw", function()
        toggle_debug_ui("watches")
      end)
      map("n", "<leader>db", function()
        toggle_debug_ui("breakpoints")
      end)
      map("n", "<leader>dS", function()
        toggle_debug_ui("scopes")
      end)
      map("n", "<leader>dc", function()
        toggle_debug_ui("console")
      end)

      vim.api.nvim_create_autocmd("BufEnter", {
        group = "DapGroup",
        pattern = "*dap-repl*",
        callback = function()
          vim.wo.wrap = true
        end,
      })

      dap.listeners.after.event_output.dapui_config = function(_, body)
        if body.category == "console" then
          dapui.eval(body.output) -- Sends stdout/stderr to Console
        end
      end

      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Attach to the process",
          hostName = "localhost",
          port = "5005",
        },
      }

      map("n", "<leader>dd", ":JdtRefreshDebugConfigs<CR>")
      map("n", "<leader>dC", ":lua require'dap'.continue()<CR>")
      map("n", "<leader>dn", ":lua require'dap'.step_over()<CR>")
      map("n", "<leader>di", ":lua require'dap'.step_into()<CR>")
      map("n", "<leader>dt", ":lua require'jdtls'.test_nearest_method()<CR>")
      map("n", "<leader>db", ":lua require'dap'.toggle_breakpoint()<CR>")
      map("n", "<leader>dB", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
      map("n", "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
      map("n", "<leader>dk", ":lua require'dapui'.toggle()<CR>")
      map("n", "<leader>dq", ":lua require'dapui'.close()<CR>")

      map("n", "<leader>dr", function()
        toggle_debug_ui("repl")
      end)
      map("n", "<leader>dS", function()
        toggle_debug_ui("stacks")
      end)
      map("n", "<leader>dw", function()
        toggle_debug_ui("watches")
      end)
      map("n", "<leader>dl", function()
        toggle_debug_ui("breakpoints")
      end)
      map("n", "<leader>ds", function()
        toggle_debug_ui("scopes")
      end)
      map("n", "<leader>dc", function()
        toggle_debug_ui("console")
      end)

      -- dap.listeners.after.event_initialized["dapui_config"] = function()
      -- dapui.open()
      -- end
      -- dap.listeners.before.event_terminated["dapui_config"] = function()
      -- dapui.close()
      -- end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      dapui.setup({
        layouts = layouts,
        enter = true,
      })
    end,
  },
}
