-- arkvim/os.lua — 跨平台小工具（Windows / macOS / Linux）
--
-- 目前用在：preview 预览、build 终端执行、keymaps 编译运行。
-- 目标：Windows 上"能用 + 不报错"，Linux/macOS 行为完全不变。

local M = {}

M.is_win = vim.fn.has("win32") == 1
M.is_mac = vim.fn.has("mac") == 1
M.is_unix = vim.fn.has("unix") == 1

--- 打开文件 / URL（交给 Neovim 内建的跨平台实现）
function M.open(target)
  if not target or target == "" then
    return false
  end
  local ok = pcall(vim.ui.open, target)
  if not ok then
    vim.notify("无法打开: " .. target, vim.log.levels.WARN)
  end
  return ok
end

--- 交互式 shell 程序的 argv（配合 Snacks.terminal 用）
function M.shell_argv(cmd)
  if M.is_win then
    local ps = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
    return { ps, "-NoProfile", "-Command", cmd }
  end
  local shell = vim.fn.executable("zsh") == 1 and "zsh"
    or vim.fn.executable("fish") == 1 and "fish"
    or "bash"
  return { shell, "-c", cmd }
end

--- 非交互执行（后台）的 argv
function M.silent_argv(cmd)
  if M.is_win then
    return { "powershell", "-NoProfile", "-Command", cmd }
  end
  return { "sh", "-c", cmd }
end

--- 把 "cd DIR && REST" 转成当前平台的写法（Windows → PowerShell）
function M.cd_cmd(cmd)
  if not M.is_win then
    return cmd
  end
  local dir, rest = cmd:match("^cd%s+(.-)%s+&&%s+(.*)$")
  if not dir then
    return cmd
  end
  -- 常见的 Unix 命令换 PowerShell 等价物
  rest = rest:gsub("rm%s+%-rf%s+([%w%._/%\\%-]+)", "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue %1")
  rest = rest:gsub("rm%s+%-f%s+([%w%._/%\\%-]+)", "Remove-Item -Force -ErrorAction SilentlyContinue %1")
  return string.format("Set-Location -LiteralPath '%s'; %s", dir:gsub("'", "''"), rest)
end

--- 结束进程（预览用）
function M.kill(pid)
  if not pid then
    return
  end
  if M.is_win then
    pcall(vim.fn.system, { "taskkill", "/F", "/T", "/PID", tostring(pid) })
  else
    pcall(vim.fn.system, { "kill", "--", tostring(pid) })
    pcall(vim.fn.system, { "kill", "-9", "--", tostring(pid) })
  end
end

--- 判断进程是否还活着
function M.alive(pid)
  if not pid then
    return false
  end
  if M.is_win then
    local out = vim.fn.system({ "tasklist", "/FI", "PID eq " .. tostring(pid), "/NH" })
    return out:find(tostring(pid), 1, true) ~= nil
  end
  return vim.fn.system({ "kill", "-0", tostring(pid) }) ~= "" or vim.v.shell_error == 0
end

--- 编译/运行时的可执行文件名后缀
function M.exe_suffix()
  return M.is_win and ".exe" or ""
end

--- 运行当前目录下可执行文件的写法
function M.run_local(name)
  return M.is_win and (".\\" .. name .. ".exe") or ("./" .. name)
end

return M
