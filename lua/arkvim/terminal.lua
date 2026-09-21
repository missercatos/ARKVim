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

-- ---------------------------------------------------------------------------
-- 终端自带光标拖影探测（通用：kitty / konsole / foot / 其他）
-- ---------------------------------------------------------------------------

--- Konsole 当前 profile 的文件内容。
--- profile 名优先取 KONSOLE_PROFILE_NAME，其次读 konsolerc 的 DefaultProfile。
local function konsole_profile_lines()
  local name = vim.env.KONSOLE_PROFILE_NAME
  if not name or name == "" then
    local section = ""
    for _, line in ipairs(read_lines(vim.fn.expand("~/.config/konsolerc"))) do
      local s = line:match("^%s*%[([^%]]+)%]")
      if s then
        section = s
      end
      if section == "Desktop Entry" then
        local v = line:match("^%s*DefaultProfile%s*=%s*(.+)$")
        if v then
          name = vim.trim(v)
        end
      end
    end
  end
  name = name or "Default.profile"
  if not name:find("%.profile$") then
    name = name .. ".profile"
  end

  local candidates = {
    vim.fn.expand("~/.local/share/konsole/") .. name,
    "/usr/share/konsole/" .. name,
    vim.fn.expand("~/.local/share/konsole/profiles/") .. name,
  }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      return read_lines(path)
    end
  end
  return {}
end

--- Konsole：光标动画（[Terminal Features] AnimatingCursorEnabled）
--- 源码 Profile.cpp 里默认值是 false，所以字段缺失时按 false 处理。
local function konsole_animating_cursor()
  for _, line in ipairs(konsole_profile_lines()) do
    local v = line:match("^%s*AnimatingCursorEnabled%s*=%s*(%w+)")
    if v then
      return v:lower() == "true"
    end
  end
  return false
end

--- 已知终端 + 它们的"拖影开关"读取方式。
--- 新增一个终端时，只要往这里加一条：match 判断是不是该终端，get 读配置判断是否开启拖影。
local TRAIL_PROBES = {
  {
    name = "kitty",
    match = function()
      return vim.env.KITTY_WINDOW_ID ~= nil
        or (vim.env.TERM or ""):lower():find("kitty", 1, true) ~= nil
    end,
    -- cursor_trail > 0 即开启
    get = function()
      for _, line in ipairs(kitty_conf()) do
        local v = line:match("^%s*cursor_trail%s+(%d+)")
        if v and tonumber(v) > 0 then
          return true
        end
      end
      return false
    end,
  },
  {
    name = "konsole",
    match = function()
      return vim.env.KONSOLE_DBUS_SERVICE ~= nil
        or vim.env.KONSOLE_DBUS_SESSION ~= nil
        or vim.env.KONSOLE_VERSION ~= nil
        or (vim.env.TERM or ""):lower():find("konsole", 1, true) ~= nil
    end,
    -- [Terminal Features] AnimatingCursorEnabled（源码默认 false）
    get = konsole_animating_cursor,
  },
  {
    name = "foot",
    match = function()
      local t = (vim.env.TERM or ""):lower()
      return t:find("foot", 1, true) ~= nil
        or (vim.env.FOOT_SERVER_SOCKET ~= nil)
    end,
    -- foot 目前没有光标拖影选项
    get = function()
      return false
    end,
  },
  {
    name = "alacritty",
    match = function()
      return vim.env.ALACRITTY_WINDOW_ID ~= nil
        or (vim.env.TERM or ""):lower():find("alacritty", 1, true) ~= nil
    end,
    -- alacritty 目前没有光标拖影选项
    get = function()
      return false
    end,
  },
}

--- 终端是否自带光标拖影。
--- 优先级：vim.g 覆盖 > 环境变量覆盖 > 已知终端探测。
--- 其他终端（或探测不准时）可显式覆盖：
---   vim.g.arkvim_native_cursor_trail = true   -- 我有原生拖影，别启插件
---   ARKVIM_NATIVE_CURSOR_TRAIL=1 nvim          -- 环境变量等价写法
function M.has_native_cursor_trail()
  local override = vim.g.arkvim_native_cursor_trail
  if override == nil then
    local env = vim.env.ARKVIM_NATIVE_CURSOR_TRAIL
    if env == "1" or env == "true" or env == "yes" then
      override = true
    elseif env == "0" or env == "false" or env == "no" then
      override = false
    end
  end
  if override ~= nil then
    return override == true
  end

  for _, probe in ipairs(TRAIL_PROBES) do
    local ok, matched = pcall(probe.match)
    if ok and matched then
      local ok2, has = pcall(probe.get)
      if ok2 and has then
        return true
      end
      -- 命中的终端没开拖影：继续看别的终端（一般不会命中多个）
    end
  end
  return false
end

--- 当前终端名字（用于提示）
function M.name()
  for _, probe in ipairs(TRAIL_PROBES) do
    local ok, matched = pcall(probe.match)
    if ok and matched then
      return probe.name
    end
  end
  local term = vim.env.TERM or "unknown"
  return term
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
