require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "Abrir linha de comando" })
map("i", "jk", "<ESC>")
