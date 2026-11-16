-- arkvim/format.lua — keep only formatters whose command actually exists.
--
-- 目的与 arkvim/lint.lua 相同：配置里写了许多可选 formatter（prettier 等），
-- 本机没装时 conform 在 format_on_save 可能产生 “command not found” 类通知。
-- VeryLazy 后过滤一次，缺失的 formatter 直接移除；format_on_save 会走
-- lsp_fallback，交给 LSP 格式化。
local M = {}

local function available(name)
  if type(name) ~= "string" then
    -- 复合 formatter（函数/表）无法静态判断，保留
    return true
  end
  local ok, fmt = pcall(function()
    return require("conform.formatters")[name]
  end)
  if not ok or type(fmt) ~= "table" then
    return false
  end
  local cmd = fmt.command
  if type(cmd) == "function" then
    return true
  end
  return type(cmd) == "string" and vim.fn.executable(cmd) == 1
end

function M.filter_missing()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end
  for ft, names in pairs(conform.formatters_by_ft or {}) do
    conform.formatters_by_ft[ft] = vim.tbl_filter(available, names)
  end
end

return M
