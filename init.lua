-- Tactical terminal detection: TERM is set by terminal emulator (foot/alacritty),
-- not inherited by other terminals spawned from it (kitty sets TERM=xterm-kitty)
local function detect_tactical()
  local term = vim.fn.getenv("TERM")
  if type(term) ~= "string" then
    return false
  end
  return term:match("^foot") ~= nil or term:match("^alacritty") ~= nil
end
vim.g.tactical = detect_tactical()

-- TTY detection: 只有 Linux 控制台（没有桌面环境）才算 TTY。
-- 注意：Windows 上 DISPLAY/WAYLAND_DISPLAY 都是空的，不能只看这两个，
-- 否则会误判成 TTY，套用绿色主题并关掉 termguicolors。
local function detect_tty()
  if vim.fn.has("linux") ~= 1 then
    return false
  end
  local display = vim.fn.getenv("DISPLAY")
  local wayland = vim.fn.getenv("WAYLAND_DISPLAY")
  return display == "" and wayland == ""
end
vim.g.is_tty = detect_tty()

-- Apply green theme if in TTY
if vim.g.is_tty then
  local tty_theme = require("config.tty-theme")
  tty_theme.apply()
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
