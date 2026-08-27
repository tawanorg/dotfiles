-- Minimal sane defaults. Swap in a distro (LazyVim etc.) whenever you want:
--   git clone https://github.com/LazyVim/starter ~/.config/nvim
local o = vim.opt
o.number = true
o.relativenumber = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.ignorecase = true
o.smartcase = true          -- a capital letter in the search makes it case-sensitive
o.termguicolors = true
o.clipboard = "unnamedplus" -- yank straight to the macOS clipboard
o.undofile = true           -- undo history survives closing the file
o.swapfile = false
o.scrolloff = 8
o.signcolumn = "yes"
o.updatetime = 250
o.splitright = true
o.splitbelow = true

vim.g.mapleader = " "
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "write" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "quit" })
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr>")
