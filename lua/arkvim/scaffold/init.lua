-- ARKVIM scaffold: framework-oriented project generator
-- Pick a framework -> type a name -> project skeleton is created.
--     <leader>pc   (see lua/config/keymaps.lua)
--
-- 模板按语言拆在 lua/arkvim/scaffold/<lang>.lua，这里只做注册表 + 选择窗口 + 生成。
-- 缺依赖时用原生 vim.notify 提示（noice/nvim-notify 特效会自动接管），不阻塞生成。

local util = require("arkvim.scaffold.util")
local notify = util.notify
local _log = vim.log.levels

local M = {}

-- ---------------------------------------------------------------------------
-- 汇总各语言模块的模板
-- ---------------------------------------------------------------------------

local MODULES = {
  "java", "kotlin", "cpp", "go", "rust",
  "python", "ruby", "php", "dart", "web",
  "systems", "scripting", "devops",
}

M.frameworks = {}

for _, mod in ipairs(MODULES) do
  local ok, m = pcall(require, "arkvim.scaffold." .. mod)
  if ok and type(m) == "table" and m.frameworks then
    vim.list_extend(M.frameworks, m.frameworks)
  else
    vim.notify("scaffold 模块加载失败: " .. mod .. " (" .. tostring(m) .. ")", _log.WARN)
  end
end

--- 某个模板的依赖是否齐全
function M.has_deps(fw)
  return util.has(fw.requires)
end

-- ---------------------------------------------------------------------------
-- 选择窗口（搜索 + 分组列表 + 缺依赖标记）
-- ---------------------------------------------------------------------------

local LIST_HEIGHT = 30
local WIN_WIDTH = 62
local SEARCH_HEIGHT = 1
local ns = vim.api.nvim_create_namespace("arkvim_picker")

local LANG_ORDER = {
  java = 1, kotlin = 2, scala = 3, c = 4, cpp = 5, csharp = 6,
  go = 7, rust = 8, zig = 9, nim = 10, crystal = 11, d = 12,
  python = 13, ruby = 14, php = 15, perl = 16, lua = 17,
  javascript = 18, typescript = 19,
  haskell = 20, ocaml = 21, lisp = 22, scheme = 23, racket = 24,
  erlang = 25, elixir = 26, clojure = 27, julia = 28, swift = 29,
  dart = 30, bash = 31, nix = 32, solidity = 33,
  css = 34, html = 35, devops = 36,
}

local function sort_frameworks()
  table.sort(M.frameworks, function(a, b)
    local la = LANG_ORDER[a.lang] or 99
    local lb = LANG_ORDER[b.lang] or 99
    if la ~= lb then return la < lb end
    return a.label < b.label
  end)
end

--- 依赖齐不齐的标记
local function dep_mark(fw)
  if M.has_deps(fw) then
    return ""
  end
  return "  ⚠ 缺依赖"
end

local function framework_picker(callback)
  sort_frameworks()
  local all = M.frameworks
  local filtered = vim.deepcopy(all)
  local cursor = 1
  local scroll_offset = 0
  local search_text = ""

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "arkvim-framework-picker"

  local total_h = SEARCH_HEIGHT + 1 + LIST_HEIGHT
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = WIN_WIDTH,
    height = total_h,
    row = math.floor((vim.o.lines - total_h) / 2),
    col = math.floor((vim.o.columns - WIN_WIDTH) / 2),
    style = "minimal",
    border = "rounded",
  })

  local function apply_filter()
    local q = search_text:lower()
    filtered = {}
    for _, f in ipairs(all) do
      if q == "" or f.label:lower():find(q, 1, true) or f.lang:lower():find(q, 1, true) then
        filtered[#filtered + 1] = f
      end
    end
    cursor = 1
    scroll_offset = 0
  end

  local function render()
    local visible = math.min(LIST_HEIGHT, #filtered)
    local sep = string.rep("─", WIN_WIDTH - 2)

    local lines = { sep }
    for i = scroll_offset + 1, math.min(scroll_offset + visible, #filtered) do
      local f = filtered[i]
      local mark = i == cursor and "> " or "  "
      lines[#lines + 1] = mark .. f.label .. dep_mark(f)
    end
    while #lines < 1 + visible + 1 do
      lines[#lines + 1] = ""
    end

    vim.api.nvim_buf_set_lines(buf, 1, -1, false, lines)

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, -1)

    local hl_row = 1 + (cursor - scroll_offset)
    if hl_row >= 2 and hl_row < 2 + visible then
      vim.api.nvim_buf_add_highlight(buf, ns, "Visual", hl_row, 0, -1)
    end

    if search_text ~= "" then
      local q = search_text:lower()
      for i, f in ipairs(filtered) do
        local row = i + 1
        if row >= 2 and row < 2 + visible then
          local label = f.label:lower()
          local start_pos = 1
          while start_pos <= #f.label do
            local s, e = label:find(q, start_pos, true)
            if not s then break end
            local byte_start = vim.fn.byteidx(f.label, s - 1)
            local byte_end = vim.fn.byteidx(f.label, e - 1) + vim.api.nvim_strwidth(f.label:sub(e, e))
            vim.api.nvim_buf_add_highlight(buf, ns, "Search", row, byte_start, byte_end)
            start_pos = e + 1
          end
        end
      end
    end
  end

  local function move(delta)
    cursor = math.max(1, math.min(#filtered, cursor + delta))
    local visible = math.min(LIST_HEIGHT, #filtered)
    if cursor <= scroll_offset then
      scroll_offset = cursor - 1
    elseif cursor > scroll_offset + visible then
      scroll_offset = cursor - visible
    end
    render()
  end

  local function select()
    local chosen = filtered[cursor]
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if chosen then callback(chosen) end
  end

  local function cancel()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local km = { buffer = buf, silent = true, nowait = true, noremap = true }

  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = function()
      local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
      search_text = first_line
      apply_filter()
      render()
    end,
  })

  local function to_insert()
    vim.cmd("startinsert!")
    pcall(vim.api.nvim_win_set_cursor, win, { 1, vim.api.nvim_strwidth(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]) })
  end

  local function to_nav()
    vim.cmd("stopinsert!")
    local row = math.min(cursor - scroll_offset, vim.api.nvim_buf_line_count(buf))
    pcall(vim.api.nvim_win_set_cursor, win, { math.max(1, row + 1), 0 })
    render()
  end

  vim.keymap.set("i", "<Esc>", to_nav, km)
  vim.keymap.set("i", "<CR>", function() vim.cmd("stopinsert"); select() end, km)
  vim.keymap.set("i", "<C-s>", function() vim.cmd("stopinsert"); select() end, km)
  vim.keymap.set("i", "<C-q>", function() vim.cmd("stopinsert"); cancel() end, km)
  vim.keymap.set("i", "<Down>", function() to_nav(); move(1) end, km)
  vim.keymap.set("i", "<Up>", function() to_nav(); move(-1) end, km)

  vim.keymap.set("n", "j", function() move(1) end, km)
  vim.keymap.set("n", "<Down>", function() move(1) end, km)
  vim.keymap.set("n", "k", function() move(-1) end, km)
  vim.keymap.set("n", "<Up>", function() move(-1) end, km)
  vim.keymap.set("n", "<C-d>", function() move(7) end, km)
  vim.keymap.set("n", "<C-u>", function() move(-7) end, km)
  vim.keymap.set("n", "G", function() cursor = #filtered; scroll_offset = math.max(0, #filtered - LIST_HEIGHT); render() end, km)
  vim.keymap.set("n", "gg", function() cursor = 1; scroll_offset = 0; render() end, km)
  vim.keymap.set("n", "<CR>", select, km)
  vim.keymap.set("n", "<Space>", select, km)
  vim.keymap.set("n", "q", cancel, km)
  vim.keymap.set("n", "<Esc>", cancel, km)
  vim.keymap.set("n", "i", to_insert, km)
  vim.keymap.set("n", "/", function()
    search_text = ""
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "" })
    apply_filter()
    render()
    to_insert()
  end, km)

  to_insert()
  render()
end

-- ---------------------------------------------------------------------------
-- entry point
-- ---------------------------------------------------------------------------

function M.create()
  framework_picker(function(framework)
    local base = vim.fn.getcwd()
    local name = vim.fn.input("项目名 (在 " .. vim.fn.fnamemodify(base, ":~") .. "): ",
      vim.fn.fnamemodify(base, ":t"))
    local ok = M.generate(framework, name, base)
    if ok then
      -- 生成完保持工作目录不变，方便继续平级创建下一个
      require("arkvim.dirs").remember_workspace(base)
      M.open_main(framework, name, base)
    end
  end)
end

--- 生成项目（可单独调用，便于测试/脚本化）
---@param framework table  M.frameworks 里的一项
---@param name string 项目名
---@param base? string 创建在哪个目录下（默认 cwd）
---@return boolean ok, string? msg
function M.generate(framework, name, base)
  base = base or vim.fn.getcwd()
  name = tostring(name or ""):gsub("%s+", "-")
  if name == "" then
    name = "myapp"
  end
  local target = base .. "/" .. name
  if vim.fn.isdirectory(target) == 1 or vim.fn.filereadable(target) == 1 then
    notify("已存在同名文件/目录: " .. target, _log.ERROR)
    return false
  end

  -- 依赖检查：缺了用原生通知提示，但继续生成骨架
  util.check(framework.requires, framework.label)

  util.mkdir_p(target)
  local ok, res = pcall(framework.gen, target, name)
  if not ok then
    notify("生成失败: " .. tostring(res), _log.ERROR)
    vim.fn.system({ "rm", "-rf", target })
    return false
  end

  M.save_metadata(target, {
    lang = framework.lang,
    label = framework.label,
    main = framework.main or "",
    workspace = base,
  })
  vim.g.arkvim_project_main = framework.main or ""

  -- 关键：不 cd 进新项目。
  -- 这样可以在同一个工作区里平级创建多个框架（不会套娃），
  -- 文件树也停在工作区、能看到所有项目。
  -- 想进去用 <leader>pE / :ArkCd；想回工作区用 <leader>pw / :ArkCd -
  notify(string.format("%s\n%s\n工作区保持: %s\n(<leader>pE 进入项目 · <leader>pu 上一级)",
    target, res, vim.fn.fnamemodify(base, ":~")))

  return true, res
end

--- 打开生成好的主文件（配合 M.generate 使用）
function M.open_main(framework, name, base)
  local main = framework.main
  if type(main) == "function" then
    main = main(name)
  end
  main = main or ""
  if main ~= "" then
    pcall(vim.cmd, "edit " .. vim.fn.fnameescape((base or vim.fn.getcwd()) .. "/" .. main))
  end
end

--- Save project metadata to stdpath("state")/arkvim/projects.json
function M.save_metadata(root, data)
  local dir = vim.fn.stdpath("state") .. "/arkvim"
  vim.fn.mkdir(dir, "p")
  local file = dir .. "/projects.json"
  local db = {}
  if vim.fn.filereadable(file) == 1 then
    local ok, decoded = pcall(vim.fn.json_decode, vim.fn.readfile(file))
    if ok and type(decoded) == "table" then db = decoded end
  end
  db[root] = data
  vim.fn.writefile({ vim.fn.json_encode(db) }, file)
end

--- Load project metadata (returns table or nil)
function M.load_metadata(root)
  local file = vim.fn.stdpath("state") .. "/arkvim/projects.json"
  if vim.fn.filereadable(file) == 0 then return nil end
  local ok, db = pcall(vim.fn.json_decode, vim.fn.readfile(file))
  if not ok or type(db) ~= "table" then return nil end
  return db[root]
end

return M
