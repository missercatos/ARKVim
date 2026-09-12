-- arkvim/capabilities.lua — project-aware capability registry
-- Each capability has: id, label, kinds (project kinds), auto (load on detection),
-- plugins (lazy specs), keys (keymaps), hint (toast text), load (function)

local M = {}

local CAPS = {}

local function add(cap)
  table.insert(CAPS, cap)
end

-- ---------------------------------------------------------------------------
-- A. auto-load on project detection (lightweight, no external binary required)
-- NOTE: Go/Python/Ruby neotest adapters are already provided by LazyVim's
-- lang extras. Node/Java adapters are registered via plugins/neotest.lua.
-- Do NOT call neotest.setup() here — it would clobber LazyVim's config.
-- ---------------------------------------------------------------------------

add({
  id = "docker-compose",
  label = "Docker Compose",
  kinds = { "docker_compose", "docker" },
  auto = true,
  plugins = {},
  hint = nil,
  load = function()
    -- devops keymaps already registered by build.lua or manual setup
  end,
})

-- ---------------------------------------------------------------------------
-- B. on-demand (heavy / external / optional) — hint only
-- ---------------------------------------------------------------------------

add({
  id = "flutter-device",
  label = "Flutter 设备/热重载",
  kinds = { "flutter", "dart" },
  auto = false,
  plugins = { "nvim-flutter/flutter-tools.nvim" },
  keys = {
    { "<leader>Xm", function() require("arkvim.mobile").flutter_menu() end, desc = "Flutter 设备" },
  },
  hint = "检测到 Flutter/Dart 项目 — 按 <leader>Xm 启动设备/热重载",
  load = function()
    local ok, ft = pcall(require, "flutter-tools")
    if ok then
      ft.setup({
        debugger = { enabled = false },
        widget_guides = { enabled = true },
        dev_log = { enabled = true },
        fvm = false,
      })
    end
  end,
})

add({
  id = "android-dev",
  label = "Android 开发",
  kinds = { "gradle", "gradle_kotlin", "spring" },
  auto = false,
  plugins = {},
  keys = {
    { "<leader>Xa", function() require("arkvim.mobile").android_menu() end, desc = "Android 设备" },
  },
  hint = "检测到 Android/Gradle 项目 — 按 <leader>Xa 构建/安装/镜像",
  load = function()
    -- already loaded
  end,
})

add({
  id = "jupyter",
  label = "Jupyter 内联执行",
  kinds = { "jupyter", "python" },
  auto = false,
  plugins = { "benlubas/molten-nvim", "michaelb/sniprun" },
  keys = {
    { "<leader>ji", function() require("arkvim.mobile").molten_init() end, desc = "Jupyter 初始化" },
    { "<leader>jl", function() require("arkvim.mobile").sniprun_run() end, desc = "行内执行" },
  },
  hint = "按 <leader>ji 初始化 molten · <leader>jl 行内执行",
  load = function()
    -- molten globals (incl. snacks.nvim image provider) are set by its plugin spec.
    local ok, sniprun = pcall(require, "sniprun")
    if ok then
      sniprun.setup({
        display = { "TemporaryCodeResult" },
      })
    end
  end,
})

add({
  id = "database",
  label = "数据库面板",
  kinds = { "docker_compose", "docker" },
  auto = false,
  plugins = { "tpope/vim-dadbod", "kristijanhusak/vim-dadbod-ui" },
  keys = {
    { "<leader>Xd", function() vim.cmd("DBUIToggle") end, desc = "数据库面板" },
  },
  hint = "按 <leader>Xd 打开数据库浏览器",
  load = function()
    -- dadbod setup
  end,
})

add({
  id = "http-client",
  label = "HTTP 客户端",
  kinds = { "node", "go", "spring", "gradle", "gradle_kotlin", "php", "python" },
  auto = false,
  plugins = { "mistweaverco/kulala.nvim" },
  keys = {
    { "<leader>Rs", function() require("kulala").run() end, desc = "Send Request", ft = "http" },
    { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "Toggle Headers/Body", ft = "http" },
    { "<leader>Rn", function() require("kulala").jump_next() end, desc = "Next Request", ft = "http" },
    { "<leader>Rp", function() require("kulala").jump_prev() end, desc = "Prev Request", ft = "http" },
  },
  hint = "按 <leader>Rs 发送 HTTP 请求（.http 文件）",
  load = function()
    local ok, kulala = pcall(require, "kulala")
    if ok then
      kulala.setup({
        default_view = "body",
      })
    end
  end,
})

add({
  id = "remote-dev",
  label = "远程开发",
  kinds = { "go", "rust", "python", "node", "java", "spring" },
  auto = false,
  plugins = { "amitds1997/remote-nvim.nvim" },
  keys = {
    { "<leader>Xr", "<cmd>RemoteStart<CR>", desc = "远程开发" },
  },
  hint = "按 <leader>Xr 连接远程开发环境",
  load = function()
    -- remote-nvim is configured by its plugin spec (config = true); nothing to do.
  end,
})

add({
  id = "octo-review",
  label = "GitHub PR Review",
  kinds = { "go", "rust", "python", "node", "java", "spring", "dart", "flutter", "php" },
  auto = false,
  plugins = { "pwntester/octo.nvim" },
  keys = {
    { "<leader>GP", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
    { "<leader>GI", "<cmd>Octo issue list<CR>", desc = "List Issues (Octo)" },
  },
  hint = "按 <leader>GP 做 PR review",
  load = function()
    local ok, octo = pcall(require, "octo")
    if ok then
      octo.setup({
        picker = "snacks",
      })
    end
  end,
})

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Get capabilities for a project kind
function M.for_kind(kind)
  local result = {}
  for _, cap in ipairs(CAPS) do
    for _, k in ipairs(cap.kinds) do
      if k == kind then
        table.insert(result, cap)
        break
      end
    end
  end
  return result
end

--- Get all capabilities
function M.all()
  return CAPS
end

--- Load a capability
function M.load(cap_id)
  for _, cap in ipairs(CAPS) do
    if cap.id == cap_id then
      if cap.plugins and #cap.plugins > 0 then
        local ok = pcall(require("lazy").load, { plugins = cap.plugins })
        if not ok then return false end
      end
      if cap.load then
        cap.load()
      end
      if cap.keys then
        for _, k in ipairs(cap.keys) do
          local opts = { desc = k.desc, silent = true, noremap = true }
          if k.ft then opts.ft = k.ft end
          vim.keymap.set("n", k[1], k[2], opts)
        end
      end
      return true
    end
  end
  return false
end

--- Auto-load capabilities for a project kind
function M.auto_load(kind)
  local caps = M.for_kind(kind)
  local loaded = {}
  for _, cap in ipairs(caps) do
    if cap.auto then
      M.load(cap.id)
      table.insert(loaded, cap.label)
    end
  end
  return loaded
end

--- Get hint texts for on-demand caps
function M.hints_for_kind(kind)
  local caps = M.for_kind(kind)
  local hints = {}
  for _, cap in ipairs(caps) do
    if not cap.auto and cap.hint then
      table.insert(hints, cap.hint)
    end
  end
  return hints
end

return M
