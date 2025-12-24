local lsp = require("lsp")
local jdtls = require("jdtls")
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local home_dir = vim.fn.expand("$HOME")
local java_home_dir = vim.fn.expand("$JAVA_HOME")
local path_to_lombak = home_dir .. "/.dotfiles/packages/lombok.jar"
local jdtls_path = vim.fn.expand("/opt/homebrew/Cellar/jdtls/**/libexec")
local jar_path = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
local config_path = jdtls_path .. "/config_mac_arm"

local project_root_name = vim.fn.system("source ~/.zshrc; getProjectName")
local workspace_project_name

if project_root_name == project_name then
  workspace_project_name = project_name
else
  workspace_project_name = project_root_name .. "-" .. project_name
end

local workspace_dir = home_dir .. "/.local/share/jdtls/" .. workspace_project_name

local on_attach = function(client, bufr)
  lsp.on_attach(client, bufr)
  jdtls.setup_dap()
  require("jdtls.dap").setup_dap_main_class_configs()
end

local get_bundles = function()
  local all_bundles = {
    vim.fn.glob(
      "$HOME/.dotfiles/packages/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar",
      1
    ),
  }
  vim.list_extend(
    all_bundles,
    vim.split(vim.fn.glob("$HOME/.dotfiles/packages/vscode-java-test/server/*.jar", true), "\n")
  )

  local ignored_bundles = { "com.microsoft.java.test.runner-jar-with-dependencies.jar", "jacocoagent.jar" }
  local find = string.find
  local function should_ignore_bundle(bundle)
    for _, ignored in ipairs(ignored_bundles) do
      if find(bundle, ignored, 1, true) then
        return true
      end
    end
  end
  local filtered_bundles = vim.tbl_filter(function(bundle)
    return bundle ~= "" and not should_ignore_bundle(bundle)
  end, all_bundles)
  return filtered_bundles
end

local config = {
  on_attach = on_attach,
  capabilities = lsp.capabilities(),

  cmd = {
    java_home_dir .. "/bin/java",

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
    jar_path,

    "-configuration",
    config_path,
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
    bundles = get_bundles(),
  },
}

-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
jdtls.start_or_attach(config)
