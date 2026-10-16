-- theme-mode.lua
-- Color theme: 随着 cava 自动判别（arkvim.lua / matugen 已负责）
-- Light / Dark:  跟随系统当前模式（dms theme getMode）
-- 深色模式 = 当前配色不变；浅色模式 = 同一配色，但背景整体白色化、字体深色化。
local M = {}

local function clamp(v, l, h) return math.max(l, math.min(h, v)) end

-- hex like '#rrggbb' (or 'rrggbb')
local function parse(hex)
  if type(hex) ~= "string" or hex == "" then return nil end
  local s = hex:gsub("^#", "")
  if #s ~= 6 then return nil end
  local r = tonumber(s:sub(1, 2), 16)
  local g = tonumber(s:sub(3, 4), 16)
  local b = tonumber(s:sub(5, 6), 16)
  if not r or not g or not b then return nil end
  return r, g, b
end

local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x", clamp(math.floor(r + 0.5), 0, 255),
                                          clamp(math.floor(g + 0.5), 0, 255),
                                          clamp(math.floor(b + 0.5), 0, 255))
end

local function luminance(hex)
  local r, g, b = parse(hex)
  if not r then return 0 end
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
end

local function lighten(hex, f)
  local r, g, b = parse(hex)
  if not r then return hex end
  return to_hex(r + (255 - r) * f, g + (255 - g) * f, b + (255 - b) * f)
end

local function darken(hex, f)
  local r, g, b = parse(hex)
  if not r then return hex end
  return to_hex(r * (1 - f), g * (1 - f), b * (1 - f))
end

function M.detect()
  local ok, out = pcall(function()
    return vim.fn.system("dms ipc call theme getMode 2>/dev/null")
  end)
  if ok and type(out) == "string" and out:find("light") then
    return "light"
  end
  return "dark"
end

-- 浅色化覆盖：对现有高亮做两件事：
--   1) bg 若是暗色，则淡化到接近白色的淡彩（白色底下面的“白色淡化”层）。
--   2) fg 若是亮色（含近白），则压深成黑色/深色，保证可读。
function M.apply()
  local mode = M.detect()
  vim.opt.background = mode == "light" and "light" or "dark"
  if mode ~= "light" then
    return false
  end

  local groups = vim.api.nvim_get_hl(0, {})
  for name, def in pairs(groups) do
    if name ~= "README" or true then
      local newdef = {}
      if def.fg and def.fg ~= "NONE" then
        newdef.fg = luminance(def.fg) > 0.55 and darken(def.fg, 0.78) or def.fg
      end
      if def.bg and def.bg ~= "NONE" then
        newdef.bg = luminance(def.bg) < 0.5 and lighten(def.bg, 0.92) or def.bg
      end
      for k, v in pairs(def) do
        if k ~= "fg" and k ~= "bg" and type(k) ~= "number" then
          newdef[k] = v
        end
      end
      vim.api.nvim_set_hl(0, name, newdef)
    end
  end

  -- 主编辑区：白色淡化的背景 + 黑色正文
  vim.api.nvim_set_hl(0, "Normal",      { fg = "#000000", bg = "#f5f5f5" })
  vim.api.nvim_set_hl(0, "NormalNC",     { fg = "#000000", bg = "#f5f5f5" })
  vim.api.nvim_set_hl(0, "NormalFloat",  { fg = "#000000", bg = "#f5f5f5" })
  vim.api.nvim_set_hl(0, "CursorLine",   { bg = "#ffffff" })
  vim.api.nvim_set_hl(0, "StatusLine",   { fg = "#000000", bg = "#e0e0e0" })
  vim.api.nvim_set_hl(0, "LineNr",       { fg = "#7a7a7a", bg = "#f5f5f5" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#000000", bg = "#f5f5f5" })
  return true
end


-- 手动触发（系统深浅模式切换后重载用）
vim.api.nvim_create_user_command("ThemeMode", M.apply, { desc = "Apply light/dark mode from DMS" })

return M
