-- config/ime.lua — 让 fcitx5 只在输入文本时生效
--
-- 背景：
--   fcitx5 处于中文状态时，空格会被输入法当作「上屏/确认」吃掉，
--   于是 <Space> leader 完全失效（连 which-key 菜单都不弹）。重启 nvim
--   会重置输入法客户端状态，所以看起来是「重启就好了」。
--
-- 方案：
--   normal / visual 一律英文直通；insert 恢复进入前的中文状态，中文输入照常可用；
--   命令行里允许临时切中文（搜索中文），离开命令行后自动回到英文。
--
-- 状态：fcitx5-remote 无参数时输出
--   0 = 输入法已关闭
--   1 = 英文（inactive）
--   2 = 中文（active）

local M = {}

local BIN = "fcitx5-remote"
local ACTIVE = 2

-- 离开 insert 前是否是中文；回到 insert 时据此恢复
local was_active = false

local function available()
  return vim.fn.executable(BIN) == 1
end

local function call(args)
  if not available() then
    return ""
  end
  local cmd = { BIN }
  vim.list_extend(cmd, args)
  local ok, out = pcall(vim.fn.system, cmd)
  if not ok then
    return ""
  end
  return vim.trim(tostring(out or ""))
end

local function state()
  return tonumber(call({})) or 0
end

-- 记住当前是不是中文，然后切回英文
local function remember_and_deactivate()
  if not available() then
    return
  end
  was_active = state() == ACTIVE
  call({ "-c" })
end

-- 只切回英文，不改变记忆（cmdline 等场景）
local function deactivate()
  if available() then
    call({ "-c" })
  end
end

-- 恢复离开前的输入法
local function activate()
  if not available() or not was_active then
    return
  end
  call({ "-o" })
end

function M.setup()
  if not available() then
    return
  end

  local grp = vim.api.nvim_create_augroup("arkvim_ime", { clear = true })

  -- 启动时如果输入法是中文，先切回英文；否则 normal 模式第一个空格就失效
  vim.api.nvim_create_autocmd("VimEnter", {
    group = grp,
    once = true,
    callback = remember_and_deactivate,
  })

  -- 输入文本：恢复中文
  vim.api.nvim_create_autocmd("InsertEnter", { group = grp, callback = activate })
  vim.api.nvim_create_autocmd("TermEnter", { group = grp, callback = activate })

  -- 回到 normal：英文直通
  vim.api.nvim_create_autocmd({ "InsertLeave", "TermLeave" }, {
    group = grp,
    callback = remember_and_deactivate,
  })
  -- 命令行里允许中文（搜索中文），但离开命令行后必须回到英文
  vim.api.nvim_create_autocmd("CmdlineLeave", { group = grp, callback = deactivate })
end

return M
