-- arkvim/dap.lua — 「调试整个项目」支持 + 诊断
--
-- 本模块提供：
--   <leader>dR / :ArkDebug run      调试整个项目
--       - 有现成 DAP 配置 → 走 dap.continue()（弹配置选择）
--       - 没有 → 用「带调试端口启动」的命令在终端跑
--   :ArkDebug status                看当前 ft/项目可用的配置、adapters、建议
--
-- 另外会在启动时注册仓颉的 lldb-dap 配置。

local M = {}

--- 注册项目级 DAP 配置（仓颉）
function M.sync_configs()
  pcall(function()
    require("arkvim.cangjie").setup_dap()
  end)
  return true
end

--- 当前文件类型有没有可用的 dap 配置
function M.configs_for(ft)
  local ok, dap = pcall(require, "dap")
  if not ok then
    return {}
  end
  return (dap.configurations or {})[ft] or {}
end

--- 调试整个项目
function M.debug_project()
  M.sync_configs()
  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("nvim-dap 未加载（<leader>d 相关键位会按需加载它）", vim.log.levels.WARN, { title = "ARKVIM" })
    return
  end

  local ft = vim.bo.filetype
  local cfgs = M.configs_for(ft)

  if #cfgs > 0 then
    -- 有配置：交给 dap 自己弹选择
    dap.continue()
    return
  end

  -- 没有配置：按项目类型用「带调试端口启动」的命令跑起来
  local proj = require("arkvim.build").project()
  if not proj then
    vim.notify(
      string.format("当前 ft=%s 没有 DAP 配置，也没检测到项目。\n:ArkDebug status 看详情", ft),
      vim.log.levels.WARN, { title = "ARKVIM" })
    return
  end
  local cmd = require("arkvim.build").debug_command(proj)
  if not cmd then
    vim.notify(
      string.format("当前 ft=%s（项目 %s）没有内置的调试启动方式。\n" ..
        "可以自己写 dap.configurations.%s，或用 <leader>Br 普通运行。", ft, proj.kind or "?", ft),
      vim.log.levels.WARN, { title = "ARKVIM" })
    return
  end
  vim.notify("以调试模式启动（终端里）…",
    vim.log.levels.INFO, { title = "ARKVIM" })
  require("arkvim.build").run_command(cmd)
end

--- 诊断
function M.status()
  M.sync_configs()
  local ft = vim.bo.filetype
  local proj = require("arkvim.build").project()
  local ok, dap = pcall(require, "dap")
  local lines = {
    "文件类型: " .. (ft ~= "" and ft or "?"),
    "项目: " .. (proj and ((proj.kind or "?") .. " @ " .. proj.root) or "未检测到"),
    "nvim-dap: " .. (ok and "已加载" or "未加载（按 <leader>dc 会加载）"),
  }
  if ok then
    local names = {}
    for _, c in ipairs(M.configs_for(ft)) do
      names[#names + 1] = c.name or (c.type .. "/" .. (c.request or "?"))
    end
    lines[#lines + 1] = "本 ft 的 DAP 配置: " .. (#names > 0 and table.concat(names, " · ") or "（无）")
    lines[#lines + 1] = "已注册 adapters: " .. table.concat(vim.tbl_keys(dap.adapters or {}), ", ")
  end
  if proj then
    local dbg = require("arkvim.build").debug_command(proj)
    lines[#lines + 1] = "内置调试启动: " .. (dbg or "（该类型没有）")
  end
  lines[#lines + 1] = "用法: <leader>dR 调试整个项目 · :ArkDebug status 看状态"
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "ARKVIM · 调试" })
end

function M.setup()
  vim.keymap.set("n", "<leader>dR", function()
    M.debug_project()
  end, { desc = "调试整个项目", silent = true })

  vim.api.nvim_create_user_command("ArkDebug", function(args)
    local sub = vim.trim(args.args or "")
    if sub == "" or sub == "run" then
      M.debug_project()
    elseif sub == "status" then
      M.status()
    else
      vim.notify("用法: :ArkDebug [run|status]", vim.log.levels.WARN, { title = "ARKVIM" })
    end
  end, {
    nargs = "?",
    desc = "调试整个项目 (run/status)",
    complete = function() return { "run", "status" } end,
  })
end

return M
