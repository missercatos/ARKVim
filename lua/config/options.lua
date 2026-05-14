-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.env.DISPLAY == nil and vim.env.WAYLAND_DISPLAY == nil then
  vim.o.termguicolors = false
end
