-- arkvim/terminal.lua — 终端能力探测（背景色 / 光标颜色 / 是否自带光标拖影）
-- 让 nvim 侧特效适配当前终端，而不是硬编码某个终端的颜色。

local M = {}

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or {}
end

-- 递归展开 kitty 的 include 指令（颜色通常写在被 include 的主题文件里）
local function kitty_config_lines(path, seen, out)
  seen = seen or {}
  out = out or {}
  if seen[path] or vim.fn.filereadable(path) == 0 then
    return out
  end
  seen[path] = true
  local dir = vim.fn.fnamemodify(path, ":h")
  for _, line in ipairs(read_lines(path)) do
    local inc = line:match("^%s*include%s+(.+)$")
    if inc then
      inc = vim.trim(inc)
      local inc_path = inc:sub(1, 1) == "/" and inc or (dir .. "/" .. inc)
      kitty_config_lines(inc_path, seen, out)
    else
      out[#out + 1] = line
    end
  end
  return out
end

local function normalize_hex(c)
  c = c:gsub("^#", "")
  if #c == 3 then
    c = c:sub(1, 1):rep(2) .. c:sub(2, 2):rep(2) .. c:sub(3, 3):rep(2)
  end
  if #c == 6 then
    return "#" .. c:upper()
  end
  return nil
end

local function is_kitty()
  local term = (vim.env.TERM or ""):lower()
  return vim.env.KITTY_WINDOW_ID ~= nil or term:find("kitty", 1, true) ~= nil
end

-- 缓存：启动时会被多次调用（background / cursor_color / cursor_trail），只读一次文件
local _kitty_lines
local function kitty_conf()
  if not _kitty_lines then
    _kitty_lines = kitty_config_lines(vim.fn.expand("~/.config/kitty/kitty.conf"))
  end
  return _kitty_lines
end

--- 从 kitty 配置里取某个键（后出现的覆盖先出现的）
local function kitty_get(lines, key)
  local value
  for _, line in ipairs(lines) do
    local v = line:match("^%s*" .. key .. "%s+([#%w]+)")
    if v then
      value = normalize_hex(v) or v
    end
  end
  return value
end

--- 终端背景色（读终端配置；探测不到返回 nil）
function M.background()
  local term = (vim.env.TERM or ""):lower()

  if is_kitty() then
    local bg = kitty_get(kitty_conf(), "background")
    if bg then
      return bg
    end
  end

  if term:find("foot", 1, true) then
    local section = ""
    for _, line in ipairs(read_lines(vim.fn.expand("~/.config/foot/foot.ini"))) do
      local s = line:match("^%s*%[([^%]]+)%]")
      if s then
        section = s
      end
      if section == "colors" then
        local v = line:match("^%s*background%s*=%s*([#%x]+)")
        if v then
          return normalize_hex(v)
        end
      end
    end
  end

  if vim.env.ALACRITTY_WINDOW_ID or term:find("alacritty", 1, true) then
    for _, line in ipairs(read_lines(vim.fn.expand("~/.config/alacritty/alacritty.toml"))) do
      local v = line:match('^%s*background%s*=%s*"([#%x]+)"')
      if v then
        return normalize_hex(v)
      end
    end
  end

  return nil
end

--- 终端是否自带光标拖影（kitty 的 cursor_trail > 0）
function M.has_native_cursor_trail()
  if is_kitty() then
    for _, line in ipairs(kitty_conf()) do
      local v = line:match("^%s*cursor_trail%s+(%d+)")
      if v and tonumber(v) > 0 then
        return true
      end
    end
  end
  return false
end

--- 是否为"富终端"：kitty + 能读到背景色配置（透明背景 / 自定义配色 / 光标拖影）。
--- 非富终端一律走 tokyonight 保底配色（不透明、原厂语法色）。
function M.rich()
  return is_kitty() and M.background() ~= nil
end

-- 光标 / 拖影 / 粒子颜色统一入口（优先从终端配置读取）。
-- 想改光标颜色：改 kitty 的 `cursor`（dank-theme.conf），或直接改这里的兜底值。
M.cursor_color = (is_kitty() and kitty_get(kitty_conf(), "cursor")) or "#e3e2e4"
M.cursor_text_color = (is_kitty() and kitty_get(kitty_conf(), "cursor_text_color")) or "#121315"

return M
