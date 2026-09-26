-- arkvim/dap.lua — 「调试整个项目」支持 + 诊断
--
-- 为什么需要它：
--   LazyVim 只为 java/go/python/ruby/rust/c/cpp/js/ts 提供了 dap.configurations，
--   Kotlin（Gradle/Android/KMP）这类框架项目没有配置 → <leader>dc 直接报
--   "No configurations found for kotlin"，也就是「没法一键调试整个项目」。
--
-- 本模块提供：
--   <leader>dR / :ArkDebug run      调试整个项目
--       - 有现成 DAP 配置 → 走 dap.continue()（弹配置选择）
--       - 没有 → 用「带调试端口启动」的命令在终端跑，并提示如何 attach
--   :ArkDebug status                看当前 ft/项目可用的配置、adapters、建议
--   :ArkDebug attach                连本地 JVM 调试端口（5005）
--
-- 另外会把 LazyVim 的 java 配置复制一份给 kotlin，并补一个通用 JVM attach。

local M = {}

local function has(bin)
  return vim.fn.executable(bin) == 1
end

--- 把 java 的 dap 配置同步给 kotlin，并补一个通用 JVM attach 配置
function M.sync_configs()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return false
  end
  dap.configurations = dap.configurations or {}

  -- kotlin 复用 java 的配置（同一个 JVM 调试器）
  if dap.configurations.java and not dap.configurations.kotlin then
    dap.configurations.kotlin = vim.deepcopy(dap.configurations.java)
  end

  -- 通用 JVM attach（配合下面的 debug 命令：以 JDWP 端口启动）
  for _, ft in ipairs({ "java", "kotlin" }) do
    dap.configurations[ft] = dap.configurations[ft] or {}
    local found = false
    for _, c in ipairs(dap.configurations[ft]) do
      if c.type == "java" and c.request == "attach" then
        found = true
      end
    end
    if not found then
      table.insert(dap.configurations[ft], {
        type = "java",
        request = "attach",
        name = "Attach to JVM (port 5005)",
        hostName = "127.0.0.1",
        port = 5005,
      })
    end
  end
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
  vim.notify("以调试模式启动（终端里）…\n启动后可用 :ArkDebug attach 连接（若等待 attach）",
    vim.log.levels.INFO, { title = "ARKVIM" })
  require("arkvim.build").run_command(cmd)
end

--- 连接本地 JVM 调试端口
function M.attach_jvm()
  M.sync_configs()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return
  end
  dap.run({
    type = "java",
    request = "attach",
    name = "Attach to JVM (port 5005)",
    hostName = "127.0.0.1",
    port = 5005,
  })
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
  lines[#lines + 1] = "用法: <leader>dR 调试整个项目 · :ArkDebug attach 连 JVM(5005)"
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
    elseif sub == "attach" then
      M.attach_jvm()
    else
      vim.notify("用法: :ArkDebug [run|status|attach]", vim.log.levels.WARN, { title = "ARKVIM" })
    end
  end, {
    nargs = "?",
    desc = "调试整个项目 (run/status/attach)",
    complete = function() return { "run", "status", "attach" } end,
  })
end

return M
