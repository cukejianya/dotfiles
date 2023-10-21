local lsp = require('lsp');
local config = require("metals").bare_config();
local dap = require("dap")

dap.configurations.scala = {
  {
    type = "scala",
    request = "launch",
    name = "RunOrTest",
    metals = {
      runType = "runOrTestFile",
      --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
    },
  },
  {
    type = "scala",
    request = "launch",
    name = "Test Target",
    metals = {
      runType = "testTarget",
    },
  },
}

local on_attach = function(client, bufr)
  require("metals").setup_dap()
  lsp.on_attach(client, bufr)
end

config.on_attach = on_attach
config.capabilities = lsp.capabilities
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require("metals").initialize_or_attach(config)
