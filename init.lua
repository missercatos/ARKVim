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

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
