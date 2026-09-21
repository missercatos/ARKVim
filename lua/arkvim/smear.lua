-- arkvim/smear.lua — smear-cursor 的开关控制
--
-- 策略：终端自带光标拖影时（kitty 的 cursor_trail 等），不启动 nvim 侧拖影插件；
-- 想强制开启用命令：
--     :ArkTrail on       开启拖影（会先把插件加载进来）
--     :ArkTrail off      关闭
--     :ArkTrail toggle   切换
--     :ArkTrail status   查看状态
--
-- 其他终端如果自带拖影但探测不到，可以在 init.lua 里覆盖：
--     vim.g.arkvim_native_cursor_trail = true
-- 或启动时带环境变量：
--     ARKVIM_NATIVE_CURSOR_TRAIL=1 nvim

local M = {}

local PLUGIN = "smear-cursor.nvim" -- lazy.nvim 的插件名（不是 repo URL）

--- 插件 Lua 模块是否已加载
function M.loaded()
  return package.loaded["smear_cursor"] ~= nil
end

--- 拖影当前是否在跑
function M.enabled()
  if not M.loaded() then
    return false
  end
  local ok, smear = pcall(require, "smear_cursor")
  return ok and smear.enabled == true
end

--- 加载插件（如果还没加载）
local function ensure_loaded()
  if M.loaded() then
    return true
  end
  local ok = pcall(require("lazy").load, { plugins = { PLUGIN } })
  if not ok or not M.loaded() then
    vim.notify("smear-cursor 加载失败（插件是否已安装？）", vim.log.levels.ERROR, { title = "ARKVIM" })
    return false
  end
  return true
end

--- 开启拖影
function M.enable(quiet)
  if not ensure_loaded() then
    return false
  end
  require("smear_cursor").enabled = true
  if not quiet then
    vim.notify("光标拖影：已开启", vim.log.levels.INFO, { title = "ARKVIM" })
  end
  return true
end

--- 关闭拖影
function M.disable(quiet)
  if not M.loaded() then
    return false
  end
  require("smear_cursor").enabled = false
  if not quiet then
    vim.notify("光标拖影：已关闭", vim.log.levels.INFO, { title = "ARKVIM" })
  end
  return true
end

--- 切换
function M.toggle()
  if M.enabled() then
    M.disable()
  else
    M.enable()
  end
end

--- 状态
function M.status()
  local terminal = require("arkvim.terminal")
  local native = terminal.has_native_cursor_trail()
  local lines = {
    "终端: " .. terminal.name(),
    "终端自带拖影: " .. (native and "是" or "否"),
    "插件已加载: " .. (M.loaded() and "是" or "否"),
    "拖影运行中: " .. (M.enabled() and "是" or "否"),
  }
  if native and not M.enabled() then
    lines[#lines + 1] = "→ 终端自带拖影，nvim 侧插件已跳过。想强制开启: :ArkTrail on"
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "ARKVIM · 光标拖影" })
end

-- 提示只显示一次（持久化），避免每次启动都弹
local function hint_shown()
  return vim.fn.filereadable(vim.fn.stdpath("state") .. "/arkvim/trail_hint_shown") == 1
end

local function mark_hint_shown()
  local dir = vim.fn.stdpath("state") .. "/arkvim"
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile({ "1" }, dir .. "/trail_hint_shown")
end

--- 启动时自动决策：终端有原生拖影就不开，否则开启
function M.auto_start()
  local terminal = require("arkvim.terminal")
  if terminal.has_native_cursor_trail() then
    if not hint_shown() then
      mark_hint_shown()
      vim.notify(
        string.format(
          "检测到 %s 自带光标拖影，已跳过 ARKVIM 拖影插件\n想强制开启: :ArkTrail on（详见 README）",
          terminal.name()
        ),
        vim.log.levels.INFO,
        { title = "ARKVIM", timeout = 5000 }
      )
    end
    return false
  end
  return M.enable(true)
end

--- 注册 :ArkTrail 命令与 <leader>us
function M.setup()
  vim.api.nvim_create_user_command("ArkTrail", function(args)
    local sub = vim.trim(args.args or "")
    if sub == "on" then
      M.enable()
    elseif sub == "off" then
      M.disable()
    elseif sub == "toggle" then
      M.toggle()
    elseif sub == "" or sub == "status" then
      M.status()
    else
      vim.notify("用法: :ArkTrail [on|off|toggle|status]", vim.log.levels.WARN, { title = "ARKVIM" })
    end
  end, {
    nargs = "?",
    desc = "光标拖影开关 (on/off/toggle/status)",
    complete = function()
      return { "on", "off", "toggle", "status" }
    end,
  })

  vim.keymap.set("n", "<leader>us", function()
    M.toggle()
  end, { desc = "光标拖影开关", silent = true })
end

return M
