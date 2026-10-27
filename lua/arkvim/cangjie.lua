-- arkvim/cangjie.lua — 仓颉：DAP 调试 + 保存后实时运行
--
-- 检测/补全/诊断由 LSP（ide4cj/cangjie.nvim 的 cjls）负责，见 lua/plugins/cangjie.lua。
-- 这里补上另外两块：
--   * 调试：系统 lldb-dap + nvim-dap；启动前自动 cjpm build -g
--   * 实时运行：保存 .cj 后自动重启 cjpm run（底部终端）
local M = {}

--- 找一个可用的仓颉/SDK 命令（优先 PATH，其次 wrappers）
local function exe(name)
  local p = vim.fn.exepath(name)
  if p ~= "" then
    return p
  end
  local w = vim.fn.expand("~/.local/share/cangjie/wrappers/" .. name)
  if vim.fn.executable(w) == 1 then
    return w
  end
  return nil
end

--- 当前文件所属的 cjpm 项目根（向上找 cjpm.toml）
function M.project_root(start)
  if not start or start == "" then
    local f = vim.api.nvim_buf_get_name(0)
    start = (f ~= "" and f:sub(1, 1) == "/") and vim.fn.fnamemodify(f, ":h") or vim.fn.getcwd()
  end
  local found = vim.fs.find("cjpm.toml", { upward = true, path = start })[1]
  return found and vim.fs.dirname(found) or nil
end

--- 找 cjpm build -g 的产物（优先 main）
local function debug_binary(root)
  local candidates = {}
  for _, pat in ipairs({
    root .. "/target/debug/bin/*",
    root .. "/target/*/debug/bin/*",
  }) do
    vim.list_extend(candidates, vim.fn.glob(pat, false, true))
  end
  local ok = {}
  for _, c in ipairs(candidates) do
    if vim.fn.filereadable(c) == 1 and vim.fn.getfperm(c):find("x") then
      ok[#ok + 1] = c
    end
  end
  for _, c in ipairs(ok) do
    if vim.fn.fnamemodify(c, ":t") == "main" then
      return c
    end
  end
  return ok[1]
end

--- 编译并返回调试用的可执行文件
function M.debug_program()
  local root = M.project_root()
  local file = vim.api.nvim_buf_get_name(0)

  if root then
    local cjpm = exe("cjpm")
    if cjpm then
      local res = vim.system({ cjpm, "build", "-g" }, { cwd = root, text = true }):wait()
      if res.code ~= 0 then
        vim.notify("cjpm build -g 失败:\n" .. (res.stderr or res.stdout or ""),
          vim.log.levels.ERROR, { title = "ARKVIM · 仓颉调试" })
        return nil
      end
      local bin = debug_binary(root)
      if bin then
        return bin
      end
      vim.notify("找不到 target/debug/bin 下的可执行文件", vim.log.levels.ERROR,
        { title = "ARKVIM · 仓颉调试" })
      return nil
    end
  end

  -- 单文件兜底：cjc -g 编译当前 .cj
  local cjc = exe("cjc")
  if cjc and file:match("%.cj$") then
    local out = vim.fn.fnamemodify(file, ":p:r")
    local res = vim.system(
      { cjc, "-g", "--set-runtime-rpath", file, "-o", out },
      { cwd = vim.fn.fnamemodify(file, ":h"), text = true }
    ):wait()
    if res.code == 0 then
      return out
    end
    vim.notify("cjc -g 编译失败:\n" .. (res.stderr or res.stdout or ""),
      vim.log.levels.ERROR, { title = "ARKVIM · 仓颉调试" })
  end
  return nil
end

--- 注册 Cangjie DAP（lldb-dap）
function M.setup_dap()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return
  end
  local lldb = exe("lldb-dap")
  if not lldb then
    return
  end

  dap.adapters.cangjie = {
    type = "executable",
    command = lldb,
    args = {},
  }

  dap.configurations.cangjie = {
    {
      type = "cangjie",
      request = "launch",
      name = "Launch Cangjie (cjpm, build -g)",
      program = function()
        return M.debug_program()
      end,
      cwd = function()
        return M.project_root() or vim.fn.getcwd()
      end,
      stopOnEntry = false,
      args = {},
    },
  }
end

-- ---------------------------------------------------------------------------
-- 实时运行：保存 .cj 后重启 cjpm run
-- ---------------------------------------------------------------------------
local watch = { enabled = false, timer = nil }

local function run_term(root, focus)
  local prev = vim.api.nvim_get_current_win()
  local old = Snacks.terminal.get({ "cjpm", "run" }, { cwd = root, create = false })
  if old then
    old:close()
  end
  vim.defer_fn(function()
    if not watch.enabled and not focus then
      return
    end
    Snacks.terminal.open({ "cjpm", "run" }, {
      cwd = root,
      win = { position = "bottom", height = 0.3 },
      auto_close = false,
      auto_insert = false,
      start_insert = false,
    })
    -- 实时运行（保存触发）不要抢走编辑焦点
    if not focus and vim.api.nvim_win_is_valid(prev) then
      vim.api.nvim_set_current_win(prev)
    end
  end, 100)
end

function M.run()
  local root = M.project_root()
  if not root then
    vim.notify("当前文件不在 cjpm 项目里", vim.log.levels.WARN, { title = "ARKVIM · 仓颉" })
    return
  end
  run_term(root, true)
end

function M.toggle_watch()
  if watch.enabled then
    watch.enabled = false
    if watch.timer then
      watch.timer:stop()
      watch.timer:close()
      watch.timer = nil
    end
    vim.notify("仓颉实时运行已关闭", vim.log.levels.INFO, { title = "ARKVIM · 仓颉" })
    return
  end
  local root = M.project_root()
  if not root then
    vim.notify("当前文件不在 cjpm 项目里", vim.log.levels.WARN, { title = "ARKVIM · 仓颉" })
    return
  end
  watch.enabled = true
  vim.notify("仓颉实时运行已开启：保存 .cj 后自动 cjpm run（再按一次关闭）",
    vim.log.levels.INFO, { title = "ARKVIM · 仓颉" })
  -- 立即跑一次，但不抢编辑焦点
  run_term(root, false)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("arkvim_cangjie", { clear = true })

  -- 打开 .cj 时注册 DAP，保证 <leader>dc / <leader>dR 能用
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "cangjie",
    callback = function()
      M.setup_dap()
    end,
  })

  -- 保存 .cj 后防抖重跑
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.cj",
    callback = function()
      if not watch.enabled then
        return
      end
      local root = M.project_root()
      if not root then
        return
      end
      if watch.timer then
        watch.timer:stop()
      else
        watch.timer = vim.uv.new_timer()
      end
      watch.timer:start(300, 0, vim.schedule_wrap(function()
        if watch.enabled then
          run_term(root)
        end
      end))
    end,
  })

  vim.keymap.set("n", "<leader>BR", M.toggle_watch, {
    desc = "watch 运行 (保存自动)",
    silent = true,
  })

  vim.api.nvim_create_user_command("ArkCangjieRun", M.run, { desc = "仓颉: 运行 cjpm 项目" })
  vim.api.nvim_create_user_command("ArkCangjieWatch", M.toggle_watch, { desc = "仓颉: 保存后自动运行" })
  vim.api.nvim_create_user_command("ArkCangjieDebug", function()
    M.setup_dap()
    require("dap").continue()
  end, { desc = "仓颉: 编译并调试项目 (lldb-dap)" })
end

return M
