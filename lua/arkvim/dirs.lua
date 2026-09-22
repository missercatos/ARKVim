-- arkvim/dirs.lua — 目录跳转（工作区 / 上一级 / 进入项目）
--
-- 解决"进了框架就回不去"的问题：
--   <leader>pu  上一级目录
--   <leader>pE  进入当前项目根目录
--   <leader>pw  回到工作区（脚手架创建项目时的基准目录）
--   :ArkCd [path|..|-]   等价命令（- = 工作区）
--
-- 文件树里也能直接上下走：<BS> 或 - 都是"回上一级"。

local M = {}

local WORKSPACE_FILE = vim.fn.stdpath("state") .. "/arkvim/workspace"

-- ---------------------------------------------------------------------------
-- 工作区记录
-- ---------------------------------------------------------------------------

--- 记住工作区（脚手架创建项目时的基准目录）
function M.remember_workspace(dir)
  dir = dir or vim.fn.getcwd()
  vim.fn.mkdir(vim.fn.fnamemodify(WORKSPACE_FILE, ":h"), "p")
  vim.fn.writefile({ dir }, WORKSPACE_FILE)
  vim.g.arkvim_workspace = dir
end

--- 读取工作区（优先级从精确到模糊）：
--- 1. 当前项目是脚手架生成的 → 用它元数据里记录的工作区
--- 2. 本次会话手动记录 / 持久化记录
--- 3. 当前项目的上一级目录
--- 4. cwd
function M.workspace()
  local proj = require("arkvim.project").current()

  if proj and proj.root then
    local okm, meta = pcall(function()
      return require("arkvim.scaffold").load_metadata(proj.root)
    end)
    if okm and meta and meta.workspace and vim.fn.isdirectory(meta.workspace) == 1 then
      return meta.workspace
    end
  end

  if vim.g.arkvim_workspace and vim.g.arkvim_workspace ~= "" then
    return vim.g.arkvim_workspace
  end

  local ok, lines = pcall(vim.fn.readfile, WORKSPACE_FILE)
  if ok and lines[1] and lines[1] ~= "" and vim.fn.isdirectory(lines[1]) == 1 then
    vim.g.arkvim_workspace = lines[1]
    return lines[1]
  end

  if proj and proj.root then
    return vim.fn.fnamemodify(proj.root, ":h")
  end
  return vim.fn.getcwd()
end

-- ---------------------------------------------------------------------------
-- cd
-- ---------------------------------------------------------------------------

--- 刷新已打开的文件树，让它跟随 cwd
local function refresh_explorer()
  local ok, pickers = pcall(function()
    return Snacks.picker.get({ source = "explorer" })
  end)
  if not ok then
    return
  end
  for _, p in ipairs(pickers) do
    pcall(function()
      p:set_cwd(vim.fn.getcwd())
      p:find()
    end)
  end
end

--- 切换工作目录（cd + 刷新文件树 + 通知）
function M.cd(path, quiet)
  if not path or path == "" then
    path = vim.fn.getcwd()
  end
  local expanded = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  expanded = expanded:gsub("/$", "")
  if vim.fn.isdirectory(expanded) ~= 1 then
    vim.notify("目录不存在: " .. tostring(path), vim.log.levels.ERROR, { title = "ARKVIM" })
    return false
  end
  vim.cmd("cd " .. vim.fn.fnameescape(expanded))
  refresh_explorer()
  if not quiet then
    vim.notify("工作目录 → " .. vim.fn.fnamemodify(expanded, ":~"), vim.log.levels.INFO, { title = "ARKVIM" })
  end
  return true
end

--- 上一级目录
function M.up()
  return M.cd(vim.fn.fnamemodify(vim.fn.getcwd(), ":h"))
end

--- 进入当前项目根目录
function M.project_root()
  local proj = require("arkvim.project").current()
  if not proj or not proj.root then
    vim.notify("未检测到项目（缺少 marker 文件）", vim.log.levels.WARN, { title = "ARKVIM" })
    return false
  end
  return M.cd(proj.root)
end

--- 回到工作区
function M.to_workspace()
  local ws = M.workspace()
  if vim.fn.isdirectory(ws) ~= 1 then
    vim.notify("记录的工作区已不存在: " .. ws, vim.log.levels.WARN, { title = "ARKVIM" })
    return false
  end
  return M.cd(ws)
end

-- ---------------------------------------------------------------------------
-- setup
-- ---------------------------------------------------------------------------

function M.setup()
  vim.api.nvim_create_user_command("ArkCd", function(args)
    local arg = vim.trim(args.args or "")
    if arg == "" then
      M.project_root()
    elseif arg == ".." then
      M.up()
    elseif arg == "-" then
      M.to_workspace()
    else
      M.cd(arg)
    end
  end, {
    nargs = "?",
    complete = "dir",
    desc = "切换工作目录 (:ArkCd [path|..|-])",
  })

  vim.keymap.set("n", "<leader>pu", M.up, { desc = "上一级目录", silent = true })
  vim.keymap.set("n", "<leader>pE", M.project_root, { desc = "进入项目根目录", silent = true })
  vim.keymap.set("n", "<leader>pw", M.to_workspace, { desc = "回到工作区", silent = true })
end

return M
