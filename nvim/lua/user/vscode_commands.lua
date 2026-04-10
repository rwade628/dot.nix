local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "<Space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- save when pressing enter
keymap("n", "<cr>", "<cmd>w<cr>", opts)
-- open find file
keymap("n", "<leader>p", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<cr>", opts)
-- open command palette
keymap("n", "<leader>P", "<cmd>lua require('vscode').action('workbench.action.showCommands')<cr>", opts)
-- reload to refresh settings
keymap("n", "<leader>r", "<cmd>lua require('vscode').action('workbench.action.reloadWindow')<cr>", opts)

-- tmux-vim
-- keymap("n", "<c-h>", "<cmd>lua require('vscode').action('workbench.action.navigateleft')<cr>", opts)
-- keymap("n", "<c-j>", "<cmd>lua require('vscode').action('workbench.action.navigatedown')<cr>", opts)
-- keymap("n", "<c-k>", "<cmd>lua require('vscode').action('workbench.action.navigateup')<cr>", opts)
-- keymap("n", "<c-l>", "<cmd>lua require('vscode').action('workbench.action.navigateright')<cr>", opts)
