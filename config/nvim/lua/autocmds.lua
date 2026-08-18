require "nvchad.autocmds"

local matugen_group = vim.api.nvim_create_augroup("MatugenThemeReload", { clear = true })
local matugen_path = vim.fn.stdpath "config" .. "/lua/themes/matugen.lua"
vim._matugen_theme_generation = (vim._matugen_theme_generation or 0) + 1
local matugen_generation = vim._matugen_theme_generation

if vim._matugen_theme_watcher then
  vim._matugen_theme_watcher:stop()
  vim._matugen_theme_watcher:close()
end

if vim._matugen_theme_timer then
  vim._matugen_theme_timer:stop()
  vim._matugen_theme_timer:close()
end

local matugen_timer = vim.uv.new_timer()
local matugen_watcher = vim.uv.new_fs_event()
vim._matugen_theme_timer = matugen_timer
vim._matugen_theme_watcher = matugen_watcher

local function apply_matugen_theme()
  if vim._matugen_theme_generation ~= matugen_generation then return end
  if loadfile(matugen_path) then
    pcall(require("nvchad.utils").reload, "themes.matugen")
  end
end

local function reload_matugen_theme()
  if vim._matugen_theme_generation ~= matugen_generation then return end
  matugen_timer:stop()
  matugen_timer:start(150, 0, function()
    vim.schedule(apply_matugen_theme)
  end)
end

matugen_watcher:start(vim.fs.dirname(matugen_path), {}, function(_, filename)
  if vim._matugen_theme_generation == matugen_generation and (not filename or filename == "matugen.lua") then
    reload_matugen_theme()
  end
end)

vim.api.nvim_create_autocmd("VimEnter", {
  group = matugen_group,
  once = true,
  callback = function()
    vim.schedule(apply_matugen_theme)
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = matugen_group,
  callback = function()
    vim._matugen_theme_generation = matugen_generation + 1
    matugen_watcher:stop()
    matugen_watcher:close()
    matugen_timer:stop()
    matugen_timer:close()
    vim._matugen_theme_watcher = nil
    vim._matugen_theme_timer = nil
  end,
})
