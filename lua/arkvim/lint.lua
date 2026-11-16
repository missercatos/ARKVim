-- arkvim/lint.lua — keep only linters that actually exist on this machine.
--
-- 为什么需要：
--   nvim-lint 在 BufWritePost / InsertLeave 会尝试运行 linters_by_ft 里的工具。
--   配置里写了不少可选 linter（eslint/luacheck/ktlint/statix…），但本机没装时
--   每次保存都会弹 “Linter not found / command not found” 之类的通知。
--   这里在 VeryLazy 后按可执行文件过滤一次，缺失的工具直接静默跳过。
local M = {}

---@param linter table?
local function available(linter)
  if type(linter) ~= "table" then
    return false
  end
  local cmd = linter.cmd
  if type(cmd) == "function" then
    local ok, resolved = pcall(cmd)
    if not ok then
      return false
    end
    cmd = resolved
  end
  return type(cmd) == "string" and vim.fn.executable(cmd) == 1
end

function M.filter_missing()
  local ok, lint = pcall(require, "lint")
  if not ok then
    return
  end

  for ft, names in pairs(lint.linters_by_ft or {}) do
    lint.linters_by_ft[ft] = vim.tbl_filter(function(name)
      local lok, linter = pcall(function()
        return lint.linters[name]
      end)
      return lok and available(linter)
    end, names)
  end
end

return M
