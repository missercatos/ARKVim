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

-- TTY detection: no desktop environment
local function detect_tty()
  local display = vim.fn.getenv("DISPLAY")
  local wayland = vim.fn.getenv("WAYLAND_DISPLAY")
  if display == "" and wayland == "" then
    return true
  end
  return false
end
vim.g.is_tty = detect_tty()

-- Apply green theme if in TTY
if vim.g.is_tty then
  local tty_theme = require("config.tty-theme")
  tty_theme.apply()
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
