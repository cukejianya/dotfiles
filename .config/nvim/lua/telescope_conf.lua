local builtin = require('telescope.builtin')

require('telescope').setup({
    defaults = {
      path_display= { "smart" },
    },
    pickers = {
      find_files = {
        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
      },
      live_grep = {
        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
      },
    },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown({}) };
    }
})

require('telescope').load_extension("ui-select")

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', 'gr', builtin.lsp_references, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fs', builtin.grep_string, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

