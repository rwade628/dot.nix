-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap.set
-- Silent keymap option
local opts = { silent = true }

-- save when pressing enter
keymap("n", "<cr>", "<cmd>w<cr>")

-- tmux-vim
keymap("n", "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", opts)
keymap("n", "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", opts)
keymap("n", "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", opts)
keymap("n", "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", opts)
keymap("n", "<C-\\>", "<Cmd>NvimTmuxNavigateLastActive<CR>", opts)
keymap("n", "<C-Space>", "<Cmd>NvimTmuxNavigateNext<CR>", opts)

-- Close buffers
keymap("n", "<S-q>", "<cmd>bdelete!<CR>", opts)
