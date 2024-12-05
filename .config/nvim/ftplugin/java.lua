local lsp = require("lsp")
local jdtls = require("jdtls")
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = "/Users/chinedumu/workspace/" .. project_name
local path_to_lombak = "/Users/chinedumu/.dotfiles/packages/lombok.jar"

local on_attach = function(client, bufr)
  -- require('jdtls').setup_dap()
  lsp.on_attach(client, bufr)
  jdtls.setup_dap({ hotcodereplace = "auto" })
  jdtls.setup.add_commands()
  require("jdtls.dap").setup_dap_main_class_configs()
end

local bundles = {
  vim.fn.glob(
    "$HOME/.dotfiles/packages/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar",
    1
  ),
}

vim.list_extend(bundles, vim.split(vim.fn.glob("$HOME/.dotfiles/packages/vscode-java-test/server/*.jar", 1), "\n"))

local config = {
  on_attach = on_attach,
  capabilities = lsp.capabilities,

  cmd = {
    "/Users/chinedumu/.sdkman/candidates/java/21.0.2-amzn/bin/java",

    --- Uncomment below to debug eclipse.jdt.ls
    -- '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044',

    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-javaagent:" .. path_to_lombak,
    "-Xms1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",

    "-jar",
    "/opt/homebrew/Cellar/jdtls/1.35.0/libexec/plugins/org.eclipse.equinox.launcher_1.6.800.v20240330-1250.jar",

    "-configuration",
    "/opt/homebrew/Cellar/jdtls/1.35.0/libexec/config_mac",
    "-data",
    workspace_dir,
  },
  root_dir = jdtls.setup.find_root({ ".git", "mvnw", "gradlew" }),

  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = bundles,
  },
}

-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
jdtls.start_or_attach(config)
