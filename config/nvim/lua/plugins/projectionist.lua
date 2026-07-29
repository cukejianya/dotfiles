return {
  "tpope/vim-projectionist",
  config = function()
    vim.g.projectionist_heuristics = {
      ["pom.xml"] = {
        -- Standard case: exact name match
        ["*/src/main/java/*.java"] = {
          alternate = "{}/src/test/java/{}Test.java",
          type = "source",
        },
        ["*/src/test/java/*Test.java"] = {
          alternate = "{}/src/main/java/{}.java",
          type = "test",
        },
        -- Integration tests
        ["*/src/test/java/*IT.java"] = {
          alternate = "{}/src/main/java/{}.java",
          type = "test",
        },
      },
    }
  end,
}
