-- arkvim/test.lua — 实时测试
--
-- neotest 的 watch 需要两件事：该语言有 neotest adapter + 有 LSP client 附加。
-- 框架项目（Kotlin/Android、Dart…）常常两者都不满足，于是 <leader>tW 直接报
-- "No position found"。
--
-- 这里统一入口：neotest 能用就用它的 watch；不能用就退回
-- arkvim.build 的「保存触发测试」（<leader>BW 同一套）。

local M = {}

--- 判断 neotest 能否为这个目标找到位置（= 有 adapter 且文件/目录像测试）
---@param target string 文件路径或目录
function M.has_position(target)
  local ok, neotest = pcall(require, "neotest")
  if not ok then
    return false
  end
  local ok2, tree = pcall(neotest.run.get_tree_from_args, target, false)
  return ok2 and tree ~= nil
end

--- 启动/停止实时测试
---@param scope "file"|"project"
---@return boolean used_neotest
function M.watch(scope)
  local target = scope == "project" and vim.fn.getcwd() or vim.fn.expand("%")
  if target == "" then
    target = vim.fn.getcwd()
  end

  if M.has_position(target) then
    local ok = pcall(function()
      require("neotest").watch.toggle(target)
    end)
    if ok then
      return true
    end
  end
  return false
end

--- 诊断：当前项目能不能用实时测试
function M.status()
  local proj = require("arkvim.project").current()
  local ft = vim.bo.filetype
  local lines = {
    "项目: " .. (proj and ((proj.kind or "?") .. " @ " .. proj.root) or "未检测到"),
    "文件类型: " .. (ft ~= "" and ft or "?"),
    "LSP clients: " .. tostring(#(vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = 0 }) or {})),
  }
  local ok, neotest = pcall(require, "neotest")
  if ok then
    local adapters = require("neotest.config").adapters or {}
    lines[#lines + 1] = "neotest adapters: " .. #adapters .. " 个"
  end
  lines[#lines + 1] = "本文件可 watch: " .. tostring(M.has_position(vim.fn.expand("%")))
  lines[#lines + 1] = "用法: <leader>tw 文件 / <leader>tW 项目；neotest 不可用会自动退回 <leader>BW"
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "ARKVIM · 测试" })
end

return M
