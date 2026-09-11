-- arkvim/hints.lua — one-time project hints + capability hub picker
-- State: stdpath("state")/arkvim/hints.json

local M = {}

local STATE_DIR = vim.fn.stdpath("state") .. "/arkvim"
local STATE_FILE = STATE_DIR .. "/hints.json"

local function ensure_dir()
  vim.fn.mkdir(STATE_DIR, "p")
end

local function load_state()
  ensure_dir()
  local f = io.open(STATE_FILE, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  if content == "" then return {} end
  local ok, data = pcall(vim.fn.json_decode, content)
  return ok and data or {}
end

local function save_state(data)
  ensure_dir()
  local f = io.open(STATE_FILE, "w")
  if not f then return end
  f:write(vim.fn.json_encode(data))
  f:close()
end

local function mark_shown(root)
  local state = load_state()
  state[root] = true
  save_state(state)
end

local function was_shown(root)
  local state = load_state()
  return state[root] == true
end

--- Show one-time project hints
function M.show(proj)
  if not proj or not proj.root then return end
  if was_shown(proj.root) then return end

  local caps = require("arkvim.capabilities")
  local hints = caps.hints_for_kind(proj.kind or "")
  if #hints == 0 then return end

  local lines = { "可用能力：" }
  for _, h in ipairs(hints) do
    table.insert(lines, "  " .. h)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, {
    title = "项目检测 · " .. (proj.label or proj.kind or ""),
    timeout = 5000,
    keep = function(_, win)
      return vim.api.nvim_win_is_valid(win)
    end,
  })

  mark_shown(proj.root)
end

--- Capability hub picker
function M.open()
  local project = require("arkvim.project")
  local caps = require("arkvim.capabilities")
  local proj = project.current()

  local items = {}

  if proj then
    table.insert(items, {
      text = string.format("%s  %s @ %s", "📁", proj.label or proj.kind or "?", proj.root),
      kind = "header",
    })

    local proj_caps = caps.for_kind(proj.kind or "")
    local loaded, on_demand, not_applicable = {}, {}, {}
    for _, cap in ipairs(proj_caps) do
      if cap.auto then
        table.insert(loaded, cap)
      else
        table.insert(on_demand, cap)
      end
    end

    for _, cap in ipairs(loaded) do
      table.insert(items, {
        text = string.format("  [已加载] %s", cap.label),
        kind = "loaded",
        cap_id = cap.id,
      })
    end

    for _, cap in ipairs(on_demand) do
      local hint = cap.hint and (" · " .. cap.hint) or ""
      table.insert(items, {
        text = string.format("  [可加载] %s%s", cap.label, hint),
        kind = "available",
        cap_id = cap.id,
      })
    end
  else
    table.insert(items, {
      text = "未检测到项目",
      kind = "header",
    })
  end

  -- Add all on-demand capabilities
  local all_caps = caps.all()
  local seen = {}
  for _, cap in ipairs(all_caps) do
    seen[cap.id] = true
  end
  for _, cap in ipairs(all_caps) do
    if not cap.auto and not seen[cap.id] then
      local hint = cap.hint and (" · " .. cap.hint) or ""
      table.insert(items, {
        text = string.format("  [可加载] %s%s", cap.label, hint),
        kind = "available",
        cap_id = cap.id,
      })
    end
  end

  if #items == 0 then
    vim.notify("没有可用的能力", vim.log.levels.INFO)
    return
  end

  Snacks.picker({
    source = {
      items = items,
      name = "能力面板",
      format = function(item) return item.text end,
      confirm = function(picker, item)
        if item and item.cap_id then
          picker:close()
          local ok = caps.load(item.cap_id)
          if ok then
            vim.notify("已加载: " .. item.text:match("%] (.+)") or item.cap_id, vim.log.levels.INFO)
          else
            vim.notify("加载失败: " .. (item.cap_id or ""), vim.log.levels.ERROR)
          end
        end
      end,
    },
  })
end

--- Show one-time ft hint
function M.ft_hint()
  local ext = vim.fn.expand("%:e")
  local ft = vim.bo.filetype
  local hints = {}

  if ext == "ipynb" or ft == "python" then
    table.insert(hints, "按 <leader>ji 初始化 molten · <leader>jl 行内执行")
  end
  if ext == "sql" or ext == "sqlite" then
    table.insert(hints, "按 <leader>Xd 打开数据库面板")
  end
  if ext == "http" then
    table.insert(hints, "按 <leader>Rs 发送请求")
  end
  if ext == "dart" then
    table.insert(hints, "按 <leader>Xm 启动 Flutter 设备")
  end

  if #hints > 0 then
    vim.notify(table.concat(hints, " · "), vim.log.levels.INFO, {
      title = "文件类型提示",
      timeout = 4000,
    })
  end
end

--- Setup: register autocmds for project detection + hints
function M.setup()
  local grp = vim.api.nvim_create_augroup("arkvim_hints", { clear = true })
  local project = require("arkvim.project")
  local caps = require("arkvim.capabilities")

  local last_root = nil

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = grp,
    callback = function()
      vim.schedule(function()
        local proj = project.current()
        if not proj or proj.root == last_root then return end
        last_root = proj.root

        -- Auto-load capabilities
        caps.auto_load(proj.kind or "")

        -- Show one-time hints
        M.show(proj)
      end)
    end,
  })

  -- One-time ft hint on first open
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = grp,
    once = true,
    callback = function()
      vim.defer_fn(function()
        M.ft_hint()
      end, 1000)
    end,
  })
end

return M
