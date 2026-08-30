-- 战术终端检测：TERM 由终端模拟器自身设置（foot/alacritty），
-- 不会被子进程启动的其他终端继承（kitty 启动时重设 TERM=xterm-kitty）
local function detect_tactical()
  local term = vim.fn.getenv("TERM")
  if type(term) ~= "string" then
    return false
  end
  return term:match("^foot") ~= nil or term:match("^alacritty") ~= nil
end
vim.g.tactical = detect_tactical()

-- TTY检测：无桌面环境
local function detect_tty()
  local display = vim.fn.getenv("DISPLAY")
  local wayland = vim.fn.getenv("WAYLAND_DISPLAY")
  if display == "" and wayland == "" then
    return true
  end
  return false
end
vim.g.is_tty = detect_tty()

-- 如果在TTY，应用绿色主题
if vim.g.is_tty then
  local tty_theme = require("config.tty-theme")
  tty_theme.apply()
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
